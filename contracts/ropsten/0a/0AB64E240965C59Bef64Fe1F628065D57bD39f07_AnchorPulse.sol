/**
 *Submitted for verification at Etherscan.io on 2019-12-03
*/
pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;
import "./safemath.sol";

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
// contract ERC20 is Context, IERC20 {
//     using SafeMath for uint256;

//     mapping (address => uint256) private _balances;

//     mapping (address => mapping (address => uint256)) private _allowances;

//     uint256 private _totalSupply;

//     /**
//      * @dev See {IERC20-totalSupply}.
//      */
//     function totalSupply() public override view returns (uint256) {
//         return _totalSupply;
//     }

//     /**
//      * @dev See {IERC20-balanceOf}.
//      */
//     function balanceOf(address account) public override view returns (uint256) {
//         return _balances[account];
//     }

//     /**
//      * @dev See {IERC20-transfer}.
//      *
//      * Requirements:
//      *
//      * - `recipient` cannot be the zero address.
//      * - the caller must have a balance of at least `amount`.
//      */
//     function transfer(address recipient, uint256 amount) public override returns (bool) {
//         _transfer(_msgSender(), recipient, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-allowance}.
//      */
//     function allowance(address owner, address spender) public override view returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     /**
//      * @dev See {IERC20-approve}.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function approve(address spender, uint256 amount) public override returns (bool) {
//         _approve(_msgSender(), spender, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-transferFrom}.
//      *
//      * Emits an {Approval} event indicating the updated allowance. This is not
//      * required by the EIP. See the note at the beginning of {ERC20};
//      *
//      * Requirements:
//      * - `sender` and `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      * - the caller must have allowance for `sender`'s tokens of at least
//      * `amount`.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
//         _transfer(sender, recipient, amount);
//         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
//         return true;
//     }

//     /**
//      * @dev Atomically increases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
//         return true;
//     }

//     /**
//      * @dev Atomically decreases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `spender` must have allowance for the caller of at least
//      * `subtractedValue`.
//      */
//     function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
//         return true;
//     }

//     /**
//      * @dev Moves tokens `amount` from `sender` to `recipient`.
//      *
//      * This is internal function is equivalent to {transfer}, and can be used to
//      * e.g. implement automatic token fees, slashing mechanisms, etc.
//      *
//      * Emits a {Transfer} event.
//      *
//      * Requirements:
//      *
//      * - `sender` cannot be the zero address.
//      * - `recipient` cannot be the zero address.
//      * - `sender` must have a balance of at least `amount`.
//      */
//     function _transfer(address sender, address recipient, uint256 amount) internal {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         require(recipient != address(0), "ERC20: transfer to the zero address");

//         _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
//         _balances[recipient] = _balances[recipient].add(amount);
//         emit Transfer(sender, recipient, amount);
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements
//      *
//      * - `to` cannot be the zero address.
//      */
//     function _mint(address account, uint256 amount) internal {
//         require(account != address(0), "ERC20: mint to the zero address");

//         _totalSupply = _totalSupply.add(amount);
//         _balances[account] = _balances[account].add(amount);
//         emit Transfer(address(0), account, amount);
//     }

//      /**
//      * @dev Destroys `amount` tokens from `account`, reducing the
//      * total supply.
//      *
//      * Emits a {Transfer} event with `to` set to the zero address.
//      *
//      * Requirements
//      *
//      * - `account` cannot be the zero address.
//      * - `account` must have at least `amount` tokens.
//      */
//     function _burn(address account, uint256 amount) internal {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
//         _totalSupply = _totalSupply.sub(amount);
//         emit Transfer(account, address(0), amount);
//     }

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
//      *
//      * This is internal function is equivalent to `approve`, and can be used to
//      * e.g. set automatic allowances for certain subsystems, etc.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `owner` cannot be the zero address.
//      * - `spender` cannot be the zero address.
//      */
//     function _approve(address owner, address spender, uint256 amount) internal {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
//      * from the caller's allowance.
//      *
//      * See {_burn} and {_approve}.
//      */
//     function _burnFrom(address account, uint256 amount) internal {
//         _burn(account, amount);
//         _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
//     }
// }

contract Liquid is IERC20, Context  {
    using SafeMath for uint256;
    mapping(address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract GlobalsAndUtility is Liquid {
    /*  XfLobbyEnter      (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  memberAddr
        uint256  indexed  entryId
        uint96            rawAmount       -->  data0 [135: 40]
        address  indexed  referrerAddr
    */
    event XfLobbyEnter(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );

    /*  XfLobbyExit       (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  memberAddr
        uint256  indexed  entryId
        uint72            xfAmount        -->  data0 [111: 40]
        address  indexed  referrerAddr
    */
    event XfLobbyExit(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );

    /*  DailyDataUpdate   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint16            beginDay        -->  data0 [ 55: 40]
        uint16            endDay          -->  data0 [ 71: 56]
        bool              isAutoUpdate    -->  data0 [ 79: 72]
        address  indexed  updaterAddr
    */
    event DailyDataUpdate(
        uint256 data0,
        address indexed updaterAddr
    );

    /*  Claim             (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        bytes20  indexed  btcAddr
        uint56            rawSatoshis     -->  data0 [ 95: 40]
        uint56            adjSatoshis     -->  data0 [151: 96]
        address  indexed  claimToAddr
        uint8             claimFlags      -->  data0 [159:152]
        uint72            claimedHearts   -->  data0 [231:160]
        address  indexed  referrerAddr
        address           senderAddr      -->  data1 [159:  0]
    */
    event Claim(
        uint256 data0,
        uint256 data1,
        bytes20 indexed btcAddr,
        address indexed claimToAddr,
        address indexed referrerAddr
    );

    /*  ClaimAssist       (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        bytes20           btcAddr         -->  data0 [199: 40]
        uint56            rawSatoshis     -->  data0 [255:200]
        uint56            adjSatoshis     -->  data1 [ 55:  0]
        address           claimToAddr     -->  data1 [215: 56]
        uint8             claimFlags      -->  data1 [223:216]
        uint72            claimedHearts   -->  data2 [ 71:  0]
        address           referrerAddr    -->  data2 [231: 72]
        address  indexed  senderAddr
    */
    event ClaimAssist(
        uint256 data0,
        uint256 data1,
        uint256 data2,
        address indexed senderAddr
    );

    /*  StakeStart        (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint16            stakedDays      -->  data0 [199:184]
        bool              isAutoStake     -->  data0 [207:200]
    */
    event StakeStart(
        uint256 data0,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    /*  StakeGoodAccounting(auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint72            payout          -->  data0 [255:184]
        uint72            penalty         -->  data1 [ 71:  0]
        address  indexed  senderAddr
    */
    event StakeGoodAccounting(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr
    );

    /*  StakeEnd          (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint72            payout          -->  data0 [255:184]
        uint72            penalty         -->  data1 [ 71:  0]
        uint16            servedDays      -->  data1 [ 87: 72]
        bool              prevUnlocked    -->  data1 [ 95: 88]
    */
    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );

    /*  ShareRateChange   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint40            shareRate       -->  data0 [ 79: 40]
        uint40   indexed  stakeId
    */
    event ShareRateChange(
        uint256 data0,
        uint40 indexed stakeId
    );

    /* Origin address */
    address internal constant ORIGIN_ADDR = 0x36F5AC03be8bC397c1ebd437D013a5adeB728870;

    /* Flush address */
    address payable internal constant FLUSH_ADDR = 0xBF44e70260052E37F84E91978aA2848A0379f594;

    /* ERC20 constants */
    string public constant name = "ANP";
    string public constant symbol = "ANP";
    uint8 public constant decimals = 8;

    uint256 private constant HEARTS_PER_HEX = 10 ** uint256(decimals); // 1e8
    uint256 private constant HEX_PER_BTC = 1e4;
    uint256 private constant SATOSHIS_PER_BTC = 1e8;
    uint256 internal constant HEARTS_PER_SATOSHI = HEARTS_PER_HEX / SATOSHIS_PER_BTC * HEX_PER_BTC;

    /* Time of contract launch (2019-12-03T00:00:00Z) */
    uint256 internal constant LAUNCH_TIME = 1575331200;

    /* Size of a Hearts or Shares uint */
    uint256 internal constant HEART_UINT_SIZE = 72;

    /* Size of a transform lobby entry index uint */
    uint256 internal constant XF_LOBBY_ENTRY_INDEX_SIZE = 40;
    uint256 internal constant XF_LOBBY_ENTRY_INDEX_MASK = (1 << XF_LOBBY_ENTRY_INDEX_SIZE) - 1;

    /* Seed for WAAS Lobby */
    uint256 internal constant WAAS_LOBBY_SEED_HEX = 1e9;
    uint256 internal constant WAAS_LOBBY_SEED_HEARTS = WAAS_LOBBY_SEED_HEX * HEARTS_PER_HEX;

    /* Start of claim phase */
    uint256 internal constant PRE_CLAIM_DAYS = 1;
    uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

    /* Length of claim phase */
    uint256 private constant CLAIM_PHASE_WEEKS = 50;
    uint256 internal constant CLAIM_PHASE_DAYS = CLAIM_PHASE_WEEKS * 7;

    /* End of claim phase */
    uint256 internal constant CLAIM_PHASE_END_DAY = CLAIM_PHASE_START_DAY + CLAIM_PHASE_DAYS;

    /* Number of words to hold 1 bit for each transform lobby day */
    uint256 internal constant XF_LOBBY_DAY_WORDS = (CLAIM_PHASE_END_DAY + 255) >> 8;

    /* BigPayDay */
    uint256 internal constant BIG_PAY_DAY = CLAIM_PHASE_END_DAY + 1;

    /* Size of a Satoshi total uint */
    uint256 internal constant SATOSHI_UINT_SIZE = 51;
    uint256 internal constant SATOSHI_UINT_MASK = (1 << SATOSHI_UINT_SIZE) - 1;

    /* Total Satoshis from supported BTC addresses in UTXO snapshot after applying Silly Whale */
    uint256 internal constant CLAIMABLE_SATOSHIS_TOTAL = 910087996911001;
    /* Number of claimable BTC addresses in UTXO snapshot */
    uint256 internal constant CLAIMABLE_BTC_ADDR_COUNT = 27997742;
    /* Percentage of total claimed Hearts that will be auto-staked from a claim */
    uint256 internal constant AUTO_STAKE_CLAIM_PERCENT = 90;

    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MIN_AUTO_STAKE_DAYS = 350;

    uint256 internal constant MAX_STAKE_DAYS = 5555; // Approx 15 years

    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;

    uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7;

    uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7;

    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusHearts() */
    uint256 private constant LPB_BONUS_PERCENT = 20;
    uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
    uint256 internal constant LPB = 364 * 100 / LPB_BONUS_PERCENT;
    uint256 internal constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100;

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusHearts() */
    uint256 private constant BPB_BONUS_PERCENT = 10;
    uint256 private constant BPB_MAX_HEX = 150 * 1e6;
    uint256 internal constant BPB_MAX_HEARTS = BPB_MAX_HEX * HEARTS_PER_HEX;
    uint256 internal constant BPB = BPB_MAX_HEARTS * 100 / BPB_BONUS_PERCENT;

    /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

    /* Constants for preparing the claim message text */
    uint8 internal constant ETH_ADDRESS_BYTE_LEN = 20;
    uint8 internal constant ETH_ADDRESS_HEX_LEN = ETH_ADDRESS_BYTE_LEN * 2;

    uint8 internal constant CLAIM_PARAM_HASH_BYTE_LEN = 12;
    uint8 internal constant CLAIM_PARAM_HASH_HEX_LEN = CLAIM_PARAM_HASH_BYTE_LEN * 2;


    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        // 1
        uint256 _lockedHeartsTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
        uint256 _stakePenaltyTotal;
        // 2
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;
        uint256 _unclaimedSatoshisTotal;
        uint256 _claimedSatoshisTotal;
        uint256 _claimedBtcAddrCount;
        //
        uint256 _currentDay;
    }

    struct GlobalsStore {
        // 1
        uint72 lockedHeartsTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
        uint72 stakePenaltyTotal;
        // 2
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
        uint128 claimStats;
    }

    GlobalsStore public globals;

    /* Claimed BTC addresses */
    mapping(bytes20 => bool) public btcAddressClaims;

    /* Daily data */
    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        uint56 dayUnclaimedSatoshisTotal;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _stakedHearts;
        uint256 _stakeShares;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
        bool _isAutoStake;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _allocSupplyCached;
        uint256 _mintOriginBatch;
        uint256 _payoutTotal;
    }

    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    mapping(uint256 => uint256) public xfLobby;
    mapping(uint256 => mapping(address => XfLobbyQueueStore)) public xfLobbyMembers;

    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Skip pre-claim period */
        require(g._currentDay > CLAIM_PHASE_START_DAY, "HEX: Too early");

        if (beforeDay != 0) {
            require(beforeDay <= g._currentDay, "HEX: beforeDay cannot be in the future");

            _dailyDataUpdate(g, beforeDay, false);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay, false);
        }

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of daily data with
     * a single call. Ugly implementation due to limitations of the standard ABI encoder.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return list Fixed array of packed values
     */
    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(beginDay < endDay && endDay <= globals.dailyDataCount, "HEX: range invalid");

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        uint256 v;
        do {
            v = uint256(dailyData[src].dayUnclaimedSatoshisTotal) << (HEART_UINT_SIZE * 2);
            v |= uint256(dailyData[src].dayStakeSharesTotal) << HEART_UINT_SIZE;
            v |= uint256(dailyData[src].dayPayoutTotal);

            list[dst++] = v;
        } while (++src < endDay);

        return list;
    }

    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * Ugly implementation due to limitations of the standard ABI encoder.
     * @return Fixed array of values
     */
    // function globalInfo()
    //     external
    //     view
    //     returns (uint256[13] memory)
    // {
    //     uint256 _claimedSatoshisTotal;
    //     uint256 _unclaimedSatoshisTotal;
    //     (_claimedSatoshisTotal, _unclaimedSatoshisTotal) = _claimStatsDecode(
    //         globals.claimStats
    //     );
    //     return [
    //         // 1
    //         globals.lockedHeartsTotal,
    //         globals.nextStakeSharesTotal,
    //         globals.shareRate,
    //         globals.stakePenaltyTotal,
    //         // 2
    //         globals.dailyDataCount,
    //         globals.stakeSharesTotal,
    //         globals.latestStakeId,
    //         _unclaimedSatoshisTotal,
    //         _claimedSatoshisTotal,
    //         //
    //         block.timestamp,
    //         totalSupply(),
    //         xfLobby[_currentDay()]
    //     ];
    // }

    /**
     * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked Hearts. allocatedSupply() includes both.
     * @return Allocated Supply in Hearts
     */
    function allocatedSupply()
        external
        view
        returns (uint256)
    {
        return totalSupply() + globals.lockedHeartsTotal;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g)
        internal
    {
        _dailyDataUpdate(g, g._currentDay, true);
    }

    function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        view
    {
        // 1
        g._lockedHeartsTotal = globals.lockedHeartsTotal;
        g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
        g._shareRate = globals.shareRate;
        g._stakePenaltyTotal = globals.stakePenaltyTotal;
        // 2
        g._dailyDataCount = globals.dailyDataCount;
        g._stakeSharesTotal = globals.stakeSharesTotal;
        g._latestStakeId = globals.latestStakeId;
        //
        g._currentDay = _currentDay();

        _globalsCacheSnapshot(g, gSnapshot);
    }

    function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        pure
    {
        // 1
        gSnapshot._lockedHeartsTotal = g._lockedHeartsTotal;
        gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
        gSnapshot._shareRate = g._shareRate;
        gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
        // 2
        gSnapshot._dailyDataCount = g._dailyDataCount;
        gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
        gSnapshot._latestStakeId = g._latestStakeId;
    }

    function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
    {
        if (g._lockedHeartsTotal != gSnapshot._lockedHeartsTotal
            || g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal
            || g._shareRate != gSnapshot._shareRate
            || g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal) {
            // 1
            globals.lockedHeartsTotal = uint72(g._lockedHeartsTotal);
            globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
            globals.shareRate = uint40(g._shareRate);
            globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
        }
        if (g._dailyDataCount != gSnapshot._dailyDataCount
            || g._stakeSharesTotal != gSnapshot._stakeSharesTotal
            || g._latestStakeId != gSnapshot._latestStakeId) {
            // 2
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
            globals.latestStakeId = g._latestStakeId;
        }
    }

    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "HEX: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._stakedHearts = stRef.stakedHearts;
        st._stakeShares = stRef.stakeShares;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
        st._isAutoStake = stRef.isAutoStake;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakeId = st._stakeId;
        stRef.stakedHearts = uint72(st._stakedHearts);
        stRef.stakeShares = uint72(st._stakeShares);
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
        stRef.isAutoStake = st._isAutoStake;
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 newStakedHearts,
        uint256 newStakeShares,
        uint256 newLockedDay,
        uint256 newStakedDays,
        bool newAutoStake
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                uint72(newStakedHearts),
                uint72(newStakeShares),
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0), // unlockedDay
                newAutoStake
            )
        );
    }

    /**
     * @dev Efficiently delete from an unordered array by moving the last element
     * to the "hole" and reducing the array length. Can change the order of the list
     * and invalidate previously held indexes.
     * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
     * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
     * @param stakeIndex Index of the element to delete
     */
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }

    /**
     * @dev Estimate the stake payout for an incomplete day
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param day Day to calculate bonuses for
     * @return payout Payout in Hearts
     */
    function _estimatePayoutRewardsDay(GlobalsCache memory g, uint256 stakeSharesParam, uint256 day)
        internal
        view
        returns (uint256 payout)
    {
        /* Prevent updating state for this estimation */
        GlobalsCache memory gTmp;
        _globalsCacheSnapshot(g, gTmp);

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedHeartsTotal;

        _dailyRoundCalc(gTmp, rs, day);

        /* Stake is no longer locked so it must be added to total as if it were */
        gTmp._stakeSharesTotal += stakeSharesParam;

        payout = rs._payoutTotal * stakeSharesParam / gTmp._stakeSharesTotal;

        // if (day == BIG_PAY_DAY) {
        //     uint256 bigPaySlice = gTmp._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI * stakeSharesParam
        //         / gTmp._stakeSharesTotal;
        //     payout += bigPaySlice + _calcAdoptionBonus(gTmp, bigPaySlice);
        // }
        return payout;
    }

    function _calcAdoptionBonus(GlobalsCache memory g, uint256 payout)
        internal
        pure
        returns (uint256)
    {
        /*
            VIRAL REWARDS: Add adoption percentage bonus to payout

            viral = payout * (claimedBtcAddrCount / CLAIMABLE_BTC_ADDR_COUNT)
        */
        uint256 viral = payout * g._claimedBtcAddrCount / CLAIMABLE_BTC_ADDR_COUNT;

        /*
            CRIT MASS REWARDS: Add adoption percentage bonus to payout

            crit  = payout * (claimedSatoshisTotal / CLAIMABLE_SATOSHIS_TOTAL)
        */
        uint256 crit = payout * g._claimedSatoshisTotal / CLAIMABLE_SATOSHIS_TOTAL;

        return viral + crit;
    }

    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
        pure
    {
        /*
            Calculate payout round

            Inflation of 3.69% inflation per 364 days             (approx 1 year)
            dailyInterestRate   = exp(log(1 + 3.69%)  / 364) - 1
                                = exp(log(1 + 0.0369) / 364) - 1
                                = exp(log(1.0369) / 364) - 1
                                = 0.000099553011616349            (approx)

            payout  = allocSupply * dailyInterestRate
                    = allocSupply / (1 / dailyInterestRate)
                    = allocSupply / (1 / 0.000099553011616349)
                    = allocSupply / 10044.899534066692            (approx)
                    = allocSupply * 10000 / 100448995             (* 10000/10000 for int precision)
        */
        rs._payoutTotal = rs._allocSupplyCached * 10000 / 100448995;

        if (day < CLAIM_PHASE_END_DAY) {
            uint256 bigPaySlice = g._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI / CLAIM_PHASE_DAYS;

            uint256 originBonus = bigPaySlice + _calcAdoptionBonus(g, rs._payoutTotal + bigPaySlice);
            rs._mintOriginBatch += originBonus;
            rs._allocSupplyCached += originBonus;

            rs._payoutTotal += _calcAdoptionBonus(g, rs._payoutTotal);
        }

        if (g._stakePenaltyTotal != 0) {
            rs._payoutTotal += g._stakePenaltyTotal;
            g._stakePenaltyTotal = 0;
        }
    }

    function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
    {
        _dailyRoundCalc(g, rs, day);

        dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
        dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
        dailyData[day].dayUnclaimedSatoshisTotal = uint56(g._unclaimedSatoshisTotal);
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate)
        private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedHeartsTotal;

        uint256 day = g._dailyDataCount;

        _dailyRoundCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal += g._nextStakeSharesTotal;
            g._nextStakeSharesTotal = 0;
        }

        while (++day < beforeDay) {
            _dailyRoundCalcAndStore(g, rs, day);
        }

        _emitDailyDataUpdate(g._dailyDataCount, day, isAutoUpdate);
        g._dailyDataCount = day;

        if (rs._mintOriginBatch != 0) {
            _mint(ORIGIN_ADDR, rs._mintOriginBatch);
        }
    }

    function _emitDailyDataUpdate(uint256 beginDay, uint256 endDay, bool isAutoUpdate)
        private
    {
        emit DailyDataUpdate( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint16(beginDay)) << 40)
                | (uint256(uint16(endDay)) << 56)
                | (isAutoUpdate ? (1 << 72) : 0),
            msg.sender
        );
    }
}

contract StakeableToken is GlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "HEX: newStakedDays lower than minimum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newStakedHearts, newStakedDays, false);

        /* Remove staked Hearts from balance of staker */
        _burn(msg.sender, newStakedHearts);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* require() is more informative than the default assert() */
        require(stakeLists[stakerAddr].length != 0, "HEX: Empty stake list");
        require(stakeIndex < stakeLists[stakerAddr].length, "HEX: stakeIndex invalid");

        StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stRef, stakeIdParam, st);

        /* Stake must have served full term */
        require(g._currentDay >= st._lockedDay + st._stakedDays, "HEX: Stake not fully served");

        /* Stake must still be locked */
        require(st._unlockedDay == 0, "HEX: Stake already unlocked");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        /* Unlock the completed stake */
        _stakeUnlock(g, st);

        /* stakeReturn value is unused here */
        (, uint256 payout, uint256 penalty, uint256 cappedPenalty) = _stakePerformance(
            g,
            st,
            st._stakedDays
        );

        _emitStakeGoodAccounting(
            stakerAddr,
            stakeIdParam,
            st._stakedHearts,
            st._stakeShares,
            payout,
            penalty
        );

        if (cappedPenalty != 0) {
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* st._unlockedDay has changed */
        _stakeUpdate(stRef, st);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "HEX: Empty stake list");
        require(stakeIndex < stakeListRef.length, "HEX: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        uint256 servedDays = 0;

        bool prevUnlocked = (st._unlockedDay != 0);
        uint256 stakeReturn;
        uint256 payout = 0;
        uint256 penalty = 0;
        uint256 cappedPenalty = 0;

        if (g._currentDay >= st._lockedDay) {
            if (prevUnlocked) {
                /* Previously unlocked in stakeGoodAccounting(), so must have served full term */
                servedDays = st._stakedDays;
            } else {
                _stakeUnlock(g, st);

                servedDays = g._currentDay - st._lockedDay;
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                } else {
                    /* Deny early-unstake before an auto-stake minimum has been served */
                    if (servedDays < MIN_AUTO_STAKE_DAYS) {
                        require(!st._isAutoStake, "HEX: Auto-stake still locked");
                    }
                }
            }

            (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(g, st, servedDays);
        } else {
            /* Deny early-unstake before an auto-stake minimum has been served */
            require(!st._isAutoStake, "HEX: Auto-stake still locked");

            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            g._nextStakeSharesTotal -= st._stakeShares;

            stakeReturn = st._stakedHearts;
        }

        _emitStakeEnd(
            stakeIdParam,
            st._stakedHearts,
            st._stakeShares,
            payout,
            penalty,
            servedDays,
            prevUnlocked
        );

        if (cappedPenalty != 0 && !prevUnlocked) {
            /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);

            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedHeartsTotal -= st._stakedHearts;

        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }

    /**
     * @dev Open a stake.
     * @param g Cache of stored globals
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     * @param newAutoStake Stake is automatic directly from a new claim
     */
    function _stakeStart(
        GlobalsCache memory g,
        uint256 newStakedHearts,
        uint256 newStakedDays,
        bool newAutoStake
    )
        internal
    {
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "HEX: newStakedDays higher than maximum");

        uint256 bonusHearts = _stakeStartBonusHearts(newStakedHearts, newStakedDays);
        uint256 newStakeShares = (newStakedHearts + bonusHearts) * SHARE_RATE_SCALE / g._shareRate;

        /* Ensure newStakedHearts is enough for at least one stake share */
        require(newStakeShares != 0, "HEX: newStakedHearts must be at least minimum shareRate");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = g._currentDay < CLAIM_PHASE_START_DAY
            ? CLAIM_PHASE_START_DAY + 1
            : g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newStakedHearts,
            newStakeShares,
            newLockedDay,
            newStakedDays,
            newAutoStake
        );

        _emitStakeStart(newStakeId, newStakedHearts, newStakeShares, newStakedDays, newAutoStake);

        /* Stake is added to total in the next round, not the current round */
        g._nextStakeSharesTotal += newStakeShares;

        /* Track total staked Hearts for inflation calculations */
        g._lockedHeartsTotal += newStakedHearts;
    }

    /**
     * @dev Calculates total stake payout including rewards for a multi-day range
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return payout Payout in Hearts
     */
    function _calcPayoutRewards(
        GlobalsCache memory g,
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {
        for (uint256 day = beginDay; day < endDay; day++) {
            payout += dailyData[day].dayPayoutTotal * stakeSharesParam
                / dailyData[day].dayStakeSharesTotal;
        }

        /* Less expensive to re-read storage than to have the condition inside the loop */
        if (beginDay <= BIG_PAY_DAY && endDay > BIG_PAY_DAY) {
            uint256 bigPaySlice = g._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI * stakeSharesParam
                / dailyData[BIG_PAY_DAY].dayStakeSharesTotal;

            payout += bigPaySlice + _calcAdoptionBonus(g, bigPaySlice);
        }
        return payout;
    }

    /**
     * @dev Calculate bonus Hearts for a new stake, if any
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     */
    function _stakeStartBonusHearts(uint256 newStakedHearts, uint256 newStakedDays)
        private
        pure
        returns (uint256 bonusHearts)
    {
        /*
            LONGER PAYS BETTER:

            If longer than 1 day stake is committed to, each extra day
            gives bonus shares of approximately 0.0548%, which is approximately 20%
            extra per year of increased stake length committed to, but capped to a
            maximum of 200% extra.

            extraDays       =  stakedDays - 1

            longerBonus%    = (extraDays / 364) * 20%
                            = (extraDays / 364) / 5
                            =  extraDays / 1820
                            =  extraDays / LPB

            extraDays       =  longerBonus% * 1820
            extraDaysMax    =  longerBonusMax% * 1820
                            =  200% * 1820
                            =  3640
                            =  LPB_MAX_DAYS

            BIGGER PAYS BETTER:

            Bonus percentage scaled 0% to 10% for the first 150M HEX of stake.

            biggerBonus%    = (cappedHearts /  BPB_MAX_HEARTS) * 10%
                            = (cappedHearts /  BPB_MAX_HEARTS) / 10
                            =  cappedHearts / (BPB_MAX_HEARTS * 10)
                            =  cappedHearts /  BPB

            COMBINED:

            combinedBonus%  =            longerBonus%  +  biggerBonus%

                                      cappedExtraDays     cappedHearts
                            =         ---------------  +  ------------
                                            LPB               BPB

                                cappedExtraDays * BPB     cappedHearts * LPB
                            =   ---------------------  +  ------------------
                                      LPB * BPB               LPB * BPB

                                cappedExtraDays * BPB  +  cappedHearts * LPB
                            =   --------------------------------------------
                                                  LPB  *  BPB

            bonusHearts     = hearts * combinedBonus%
                            = hearts * (cappedExtraDays * BPB  +  cappedHearts * LPB) / (LPB * BPB)
        */
        uint256 cappedExtraDays = 0;

        /* Must be more than 1 day for Longer-Pays-Better */
        if (newStakedDays > 1) {
            cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
        }

        uint256 cappedStakedHearts = newStakedHearts <= BPB_MAX_HEARTS
            ? newStakedHearts
            : BPB_MAX_HEARTS;

        bonusHearts = cappedExtraDays * BPB + cappedStakedHearts * LPB;
        bonusHearts = newStakedHearts * bonusHearts / (LPB * BPB);

        return bonusHearts;
    }

    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
        private
        pure
    {
        g._stakeSharesTotal -= st._stakeShares;
        st._unlockedDay = g._currentDay;
    }

    function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays)
        private
        view
        returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty)
    {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                g,
                st._lockedDay,
                st._stakedDays,
                servedDays,
                st._stakeShares
            );
            stakeReturn = st._stakedHearts + payout;
        } else {
            // servedDays must == stakedDays here
            payout = _calcPayoutRewards(
                g,
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
            stakeReturn = st._stakedHearts + payout;

            penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                /* Cannot have a negative stake return */
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                /* Remove penalty from the stake return */
                cappedPenalty = penalty;
                stakeReturn -= cappedPenalty;
            }
        }
        return (stakeReturn, payout, penalty, cappedPenalty);
    }

    function _calcPayoutAndEarlyPenalty(
        GlobalsCache memory g,
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 servedDays,
        uint256 stakeSharesParam
    )
        private
        view
        returns (uint256 payout, uint256 penalty)
    {
        uint256 servedEndDay = lockedDayParam + servedDays;

        /* 50% of stakedDays (rounded up) with a minimum applied */
        uint256 penaltyDays = (stakedDaysParam + 1) / 2;
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }

        if (servedDays == 0) {
            /* Fill penalty days with the estimated average payout */
            uint256 expected = _estimatePayoutRewardsDay(g, stakeSharesParam, lockedDayParam);
            penalty = expected * penaltyDays;
            return (payout, penalty); // Actual payout was 0
        }

        if (penaltyDays < servedDays) {
            /*
                Simplified explanation of intervals where end-day is non-inclusive:

                penalty:    [lockedDay  ...  penaltyEndDay)
                delta:                      [penaltyEndDay  ...  servedEndDay)
                payout:     [lockedDay  .......................  servedEndDay)
            */
            uint256 penaltyEndDay = lockedDayParam + penaltyDays;
            penalty = _calcPayoutRewards(g, stakeSharesParam, lockedDayParam, penaltyEndDay);

            uint256 delta = _calcPayoutRewards(g, stakeSharesParam, penaltyEndDay, servedEndDay);
            payout = penalty + delta;
            return (payout, penalty);
        }

        /* penaltyDays >= servedDays  */
        payout = _calcPayoutRewards(g, stakeSharesParam, lockedDayParam, servedEndDay);

        if (penaltyDays == servedDays) {
            penalty = payout;
        } else {
            /*
                (penaltyDays > servedDays) means not enough days served, so fill the
                penalty days with the average payout from only the days that were served.
            */
            penalty = payout * penaltyDays / servedDays;
        }
        return (payout, penalty);
    }

    function _calcLatePenalty(
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 unlockedDayParam,
        uint256 rawStakeReturn
    )
        private
        pure
        returns (uint256)
    {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay = lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }

        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn * (unlockedDayParam - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
    }

    function _splitPenaltyProceeds(GlobalsCache memory g, uint256 penalty)
        private
    {
        /* Split a penalty 50:50 between Origin and stakePenaltyTotal */
        uint256 splitPenalty = penalty / 2;

        if (splitPenalty != 0) {
            _mint(ORIGIN_ADDR, splitPenalty);
        }

        /* Use the other half of the penalty to account for an odd-numbered penalty */
        splitPenalty = penalty - splitPenalty;
        g._stakePenaltyTotal += splitPenalty;
    }

    function _shareRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn)
        private
    {
        if (stakeReturn > st._stakedHearts) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            uint256 bonusHearts = _stakeStartBonusHearts(stakeReturn, st._stakedDays);
            uint256 newShareRate = (stakeReturn + bonusHearts) * SHARE_RATE_SCALE / st._stakeShares;

            if (newShareRate > SHARE_RATE_MAX) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = SHARE_RATE_MAX;
            }

            if (newShareRate > g._shareRate) {
                g._shareRate = newShareRate;

                _emitShareRateChange(newShareRate, st._stakeId);
            }
        }
    }

    function _emitStakeStart(
        uint40 stakeId,
        uint256 stakedHearts,
        uint256 stakeShares,
        uint256 stakedDays,
        bool isAutoStake
    )
        private
    {
        emit StakeStart( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint16(stakedDays)) << 184)
                | (isAutoStake ? (1 << 200) : 0),
            msg.sender,
            stakeId
        );
    }

    function _emitStakeGoodAccounting(
        address stakerAddr,
        uint40 stakeId,
        uint256 stakedHearts,
        uint256 stakeShares,
        uint256 payout,
        uint256 penalty
    )
        private
    {
        emit StakeGoodAccounting( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint72(payout)) << 184),
            uint256(uint72(penalty)),
            stakerAddr,
            stakeId,
            msg.sender
        );
    }

    function _emitStakeEnd(
        uint40 stakeId,
        uint256 stakedHearts,
        uint256 stakeShares,
        uint256 payout,
        uint256 penalty,
        uint256 servedDays,
        bool prevUnlocked
    )
        private
    {
        emit StakeEnd( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint72(payout)) << 184),
            uint256(uint72(penalty))
                | (uint256(uint16(servedDays)) << 72)
                | (prevUnlocked ? (1 << 88) : 0),
            msg.sender,
            stakeId
        );
    }

    function _emitShareRateChange(uint256 shareRate, uint40 stakeId)
        private
    {
        emit ShareRateChange( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint40(shareRate)) << 40),
            stakeId
        );
    }
}

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}



contract TransformableToken is StakeableToken {
    /**
     * @dev PUBLIC FACING: Enter the tranform lobby for the current round
     * @param referrerAddr Eth address of referring user (optional; 0x0 for no referrer)
     */
    function xfLobbyEnter(address referrerAddr)
        external
        payable
    {
        uint256 enterDay = _currentDay();
        require(enterDay < CLAIM_PHASE_END_DAY, "HEX: Lobbies have ended");

        uint256 rawAmount = msg.value;
        require(rawAmount != 0, "HEX: Amount required");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 entryIndex = qRef.tailIndex++;

        qRef.entries[entryIndex] = XfLobbyEntryStore(uint96(rawAmount), referrerAddr);

        xfLobby[enterDay] += rawAmount;

        _emitXfLobbyEnter(enterDay, entryIndex, rawAmount, referrerAddr);
    }

    /**
     * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
     * @param enterDay Day number when the member entered
     * @param count Number of queued-enters to exit (optional; 0 for all)
     */
    function xfLobbyExit(uint256 enterDay, uint256 count)
        external
    {
        require(enterDay < _currentDay(), "HEX: Round is not complete");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 headIndex = qRef.headIndex;
        uint256 endIndex;

        if (count != 0) {
            require(count <= qRef.tailIndex - headIndex, "HEX: count invalid");
            endIndex = headIndex + count;
        } else {
            endIndex = qRef.tailIndex;
            require(headIndex < endIndex, "HEX: count invalid");
        }

        uint256 waasLobby = _waasLobby(enterDay);
        uint256 _xfLobby = xfLobby[enterDay];
        uint256 totalXfAmount = 0;
        uint256 originBonusHearts = 0;

        do {
            uint256 rawAmount = qRef.entries[headIndex].rawAmount;
            address referrerAddr = qRef.entries[headIndex].referrerAddr;

            delete qRef.entries[headIndex];

            uint256 xfAmount = waasLobby * rawAmount / _xfLobby;

            if (referrerAddr == address(0)) {
                /* No referrer */
                _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
            } else {
                /* Referral bonus of 10% of xfAmount to member */
                uint256 referralBonusHearts = xfAmount / 10;

                xfAmount += referralBonusHearts;

                /* Then a cumulative referrer bonus of 20% to referrer */
                uint256 referrerBonusHearts = xfAmount / 5;

                if (referrerAddr == msg.sender) {
                    /* Self-referred */
                    xfAmount += referrerBonusHearts;
                    _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
                } else {
                    /* Referred by different address */
                    _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
                    _mint(referrerAddr, referrerBonusHearts);
                }
                originBonusHearts += referralBonusHearts + referrerBonusHearts;
            }

            totalXfAmount += xfAmount;
        } while (++headIndex < endIndex);

        qRef.headIndex = uint40(headIndex);

        if (originBonusHearts != 0) {
            _mint(ORIGIN_ADDR, originBonusHearts);
        }
        if (totalXfAmount != 0) {
            _mint(msg.sender, totalXfAmount);
        }
    }

    /**
     * @dev PUBLIC FACING: Release any value that has been sent to the contract
     */
    function xfLobbyFlush()
        external
    {
        require(address(this).balance != 0, "HEX: No value");

        FLUSH_ADDR.transfer(address(this).balance);
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
     * a single call
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return list Fixed array of values
     */
    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(
            beginDay < endDay && endDay <= CLAIM_PHASE_END_DAY && endDay <= _currentDay(),
            "HEX: invalid range"
        );

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            list[dst++] = uint256(xfLobby[src++]);
        } while (src < endDay);

        return list;
    }

    /**
     * @dev PUBLIC FACING: Return a current lobby member queue entry.
     * Only needed due to limitations of the standard ABI encoder.
     * @param memberAddr Eth address of the lobby member
     * @param entryId 49 bit compound value. Top 9 bits: enterDay, Bottom 40 bits: entryIndex
     * @return rawAmount refererAddr 1: Raw amount that was entered with; 2: Referring Eth addr (optional; 0x0 for no referrer)
     */
    function xfLobbyEntry(address memberAddr, uint256 entryId)
        external
        view
        returns (uint256 rawAmount, address referrerAddr)
    {
        uint256 enterDay = entryId >> XF_LOBBY_ENTRY_INDEX_SIZE;
        uint256 entryIndex = entryId & XF_LOBBY_ENTRY_INDEX_MASK;

        XfLobbyEntryStore storage entry = xfLobbyMembers[enterDay][memberAddr].entries[entryIndex];

        require(entry.rawAmount != 0, "HEX: Param invalid");

        return (entry.rawAmount, entry.referrerAddr);
    }

    /**
     * @dev PUBLIC FACING: Return the lobby days that a user is in with a single call
     * @param memberAddr Eth address of the user
     * @return words Bit vector of lobby day numbers
     */
    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[XF_LOBBY_DAY_WORDS] memory words)
    {
        uint256 day = _currentDay() + 1;

        if (day > CLAIM_PHASE_END_DAY) {
            day = CLAIM_PHASE_END_DAY;
        }

        while (day-- != 0) {
            if (xfLobbyMembers[day][memberAddr].tailIndex > xfLobbyMembers[day][memberAddr].headIndex) {
                words[day >> 8] |= 1 << (day & 255);
            }
        }

        return words;
    }

    function _waasLobby(uint256 enterDay)
        private
        returns (uint256 waasLobby)
    {
        if (enterDay >= CLAIM_PHASE_START_DAY) {
            GlobalsCache memory g;
            GlobalsCache memory gSnapshot;
            _globalsLoad(g, gSnapshot);

            _dailyDataUpdateAuto(g);

            uint256 unclaimed = dailyData[enterDay].dayUnclaimedSatoshisTotal;
            waasLobby = unclaimed * HEARTS_PER_SATOSHI / CLAIM_PHASE_DAYS;

            _globalsSync(g, gSnapshot);
        } else {
            waasLobby = WAAS_LOBBY_SEED_HEARTS;
        }
        return waasLobby;
    }

    function _emitXfLobbyEnter(
        uint256 enterDay,
        uint256 entryIndex,
        uint256 rawAmount,
        address referrerAddr
    )
        private
    {
        emit XfLobbyEnter( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint96(rawAmount)) << 40),
            msg.sender,
            (enterDay << XF_LOBBY_ENTRY_INDEX_SIZE) | entryIndex,
            referrerAddr
        );
    }

    function _emitXfLobbyExit(
        uint256 enterDay,
        uint256 entryIndex,
        uint256 xfAmount,
        address referrerAddr
    )
        private
    {
        emit XfLobbyExit( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(xfAmount)) << 40),
            msg.sender,
            (enterDay << XF_LOBBY_ENTRY_INDEX_SIZE) | entryIndex,
            referrerAddr
        );
    }
}

contract AnchorPulse is TransformableToken {
    using SafeMath for uint256;
    constructor()
        public
    {
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);

        /* Initialize dailyDataCount to skip pre-claim period */
        globals.dailyDataCount = uint16(PRE_CLAIM_DAYS);

    }
    struct slice {uint _len; uint _ptr;}
    function launchMint(string[] calldata pair) external {
      for(uint i = 0; i < pair.length; i++) {

        // slice memory amountStr = pair[i].toSlice();
        // amountStr.beyond(":".toSlice());

        // slice memory addressStr = pair[i].toSlice();
        // addressStr.until(":".toSlice());

        // address reciever = parseAddr(addressStr); 
        // uint amount = stringToUint(amountStr);  
        // _balances[reciever] += amount;
      }
    }

    // function stringToUint(string memory s) internal pure returns (uint result) {
    //   bytes memory b = bytes(s);
    //   uint i;
    //   result = 0;
    //   for (i = 0; i < b.length; i++) {
    //     uint c = uint(b[i]);
    //     if (c >= 48 && c <= 57) {
    //       result = result * 10 + (c - 48);
    //     }
    //   }
    // }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

}