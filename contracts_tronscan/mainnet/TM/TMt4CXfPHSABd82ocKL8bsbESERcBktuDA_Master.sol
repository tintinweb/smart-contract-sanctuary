//SourceUnit: AddressSetLib.sol

pragma solidity 0.5.8;


library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getSize(AddressSet storage set) public view returns (uint256) {
        return set.elements.length;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}


//SourceUnit: ERC20Detailed.sol

pragma solidity 0.5.8;

import "./SafeMath.sol";

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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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

        _balances[sender] = _balances[sender].sub(amount);
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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

//SourceUnit: FHBToken.sol

pragma solidity 0.5.8;

import './ERC20Detailed.sol';

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract FHBToken is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("FHB", "FHB", 12) {
        _mint(msg.sender, 10000 * (10 ** uint256(decimals())));
    }
}

//SourceUnit: ITRC20.sol

pragma solidity 0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: KOTToken.sol

pragma solidity 0.5.8;

import './ERC20Detailed.sol';

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract KOTToken is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("KOT", "KOT", 8) {
        _mint(msg.sender, 60000 * (10 ** uint256(decimals())));
    }
}

//SourceUnit: Master.sol

pragma solidity 0.5.8;

import "./Pausable.sol";
import "./SafeMath.sol";
import './TransferHelper.sol';
import './ITRC20.sol';
import "./AddressSetLib.sol";

import "./Rank.sol";
import './Refer.sol';

contract Master is Pausable, Rank {
    using SafeMath for uint256;
    using AddressSetLib for AddressSetLib.AddressSet;

    struct Miner {
        uint256 id; // miner id
        address owner; // owner address
        bytes32 name; // miner name
        uint256 lpAmount; // team LP total staked
        uint256 totalAddress; // total invite accounts
        bool whitelist;
    }

    struct Studio {
        address owner;
        bytes32 name;
        bytes32 city;
        bytes32 headName;
        bytes32 telephone;
        bool approved;
        bool rejected;
        bytes32 reason;
    }

    struct UserInfo {
        uint256 lpAmount; // lp staked
        uint256 kotAmount; // kot staked
        uint256 rewardDebtLP;
        uint256 rewardDebtKot;
        uint256 reward; // mining reward
        uint256 released; // released KOT reward
        uint256 vestingKOTStart;
        uint256 rewardDebtFHBLP;
        uint256 rewardDebtFHBKot;
        uint256 rewardFHB; // FHB reward
        uint256 releasedFHB; // released FHB reward
        uint256 vestingFHBStart;
    }

    // miner FHB reward
    mapping(address => uint256) public minerFHBReward; // first 400 miner fhb reward

    // miner studio KOT reward
    mapping(address => uint256) public studioReward;

    // invite KOT reward
    mapping(address => uint256) public inviteReward;

    // user staking info
    mapping (address => UserInfo) public userInfo;

    // user miner info
    mapping (address => Miner) public minerInfo;

    AddressSetLib.AddressSet internal minerWhiteList;

    // studio info
    mapping (address => Studio ) public studioInfo;
    AddressSetLib.AddressSet internal studioWhiteList;
    AddressSetLib.AddressSet internal pendingStudio;
    AddressSetLib.AddressSet internal removedStudio;

    // KOT token
    address public kot;

    // FHB token
    address public fhb;

    // LP token
    address public lp;

    Refer public refer;

    // miner id idx
    uint256 minerID = 0;

    // min LP amount for miner
    uint256 public sysMinerMinLPStaked = 10000 * (10 ** 6);
    uint256 public sysStudioInviteMinerCount = 10;

    // LP pool, total 6000 KOT reward
    uint256 public sysLPPoolMaxKOTReward = 6000 * (10 ** 8); // LP stake total KOT reward
    uint256 public sysLPPoolKOTPerSecond = 77160; // 6000 * (10 ** 8) / (3600 * 24 * 90)

    // KOT pool, total 3000 KOT reward
    uint256 public sysKOTPoolMaxKOTReward = 3000 * (10 ** 8); // KOT stake total reward
    uint256 public sysKOTPoolKOTPerSecond = 38580; // 3000 *  (10 ** 8) / (3600 * 24 * 90)

    // LP pool, total 4000 FHB reward
    uint256 public sysLPPoolMaxFHBReward = 4000 * (10 ** 12); // LP stake total FHB reward
    uint256 public sysLPPoolFHBPerSecond = 1543209876; // 4000 * (10 ** 12) / (3600 * 24 * 30)

    // KOT pool, total 2000 FHB reward
    uint256 public sysKOTPoolMaxFHBReward = 2000 * (10 ** 12); // KOT stake total FHB reward
    uint256 public sysKOTPoolFHBPerSecond = 771604938; // 2000 *  (10 ** 12) / (3600 * 24 * 30)

    uint256 private constant ACC_PRECISION = 1e12;

    // invite total 1800 KOT reward
    uint256 public INVITE_POOL_MAX_REWARD = 1800 * (10 ** 8); // inviter total reward
    uint256 public sysInviteRewardPercent = 20; // invite reward percent

    // miner FHB reward, total 4000 FHB
    uint256 public MINER_EXTRA_FHB_REWARD = 10 * (10 ** 12); // miner extra FHB reward
    uint256 public sysMaxMinerCountWithFHBReward = 400;

    // studio extra kot reward, total 13000 KOT
    uint256 public STUDIO_EXTRA_KOT_REWARD = 100 * (10 ** 8); // single studio kot reward
    uint256 public sysMaxStudioCount = 130; // max studio count in whitelist

    uint256 public currentStudioCount = 0;
    uint256 public currentMinerCount = 0;

    struct PoolInfo {
        uint256 totalRewardKOT; // current KOT reward of pool
        uint256 totalRewardFHB; // current FHB reward of pool
        uint256 accKOTPerShare; //  times ACC_PRECISION
        uint256 accFHBPerShare; //  times ACC_PRECISION
        uint256 lastRewardTime;
    }
    PoolInfo public lpPoolInfo; // LP pool params
    PoolInfo public kotPoolInfo; // KOT pool params

    uint256 public sysStartTime; // mining start time
    uint256 public sysKotMiningEndTime; // kot mining end time
    uint256 public sysFhbMiningEndTime; // fhb mining end time

    // stat info
    uint256 public kotTotalStaking; // total KOT staked

    // total invite reward
    uint256 public totalInviteReward;

    uint256 public sysVestingKOTDuration = 90 days;
    uint256 public sysVestingFHBDuration = 30 days;

    // Events
    event StakeLP(address indexed user, uint256 amount);
    event UnStakeLP(address indexed user, uint256 amount);
    event StakeKOT(address indexed user, uint256 amount);
    event UnStakeKOT(address indexed user, uint256 amount);
    event VestingKOTReleased(address indexed user, uint256 amount);
    event VestingFHBReleased(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 tp, uint256 amount);
    event WithdrawFHBBonus(address indexed user, uint256 amount);

    constructor (
        address _kot,
        address _lp,
        address _fhb,
        Refer _refer
    ) public {
        kot = _kot;
        lp = _lp;
        fhb = _fhb;
        refer = _refer;
    }

    // init mining params
    function init(uint256 _startTime) public onlyOwner {
        sysStartTime = _startTime;
        sysFhbMiningEndTime = _startTime + 30 days;
        sysKotMiningEndTime = _startTime + 90 days;

        lpPoolInfo.lastRewardTime = _startTime;
        kotPoolInfo.lastRewardTime = _startTime;
    }

    // total KOT reward
    function getTotalKOTReward() public view returns (uint256) {
        uint256 total = 0;
        total = total.add(lpPoolInfo.totalRewardKOT).add(kotPoolInfo.totalRewardKOT).add(totalInviteReward);
        return total;
    }

    // total FHB reward
    function getTotalFHBReward() public view returns (uint256) {
        return (lpPoolInfo.totalRewardFHB).add(kotPoolInfo.totalRewardFHB);
    }

    // user total reward
    function getUserTotalKOTReward(address usr) public view returns (uint256) {
        UserInfo storage info = userInfo[usr];
        uint256 total = info.reward.add(inviteReward[usr]).add(studioReward[usr]);
        return total;
    }

    // user total reward
    function getUserTotalFHBReward(address usr) public view returns (uint256) {
        return (minerFHBReward[usr]).add(userInfo[usr].rewardFHB);
    }

    function isStudioQualified(address usr) public view returns (bool) {
        if (!isMiner(usr)) { // must be a miner
            return false;
        }

        if (userInfo[usr].lpAmount < sysMinerMinLPStaked) { // check miner's LP
            return false;
        }

        // check miner's invite addresses
        uint256 count = 0;
        address[] memory addrs = getInviteList(usr);
        for (uint256 i = 0; i < addrs.length; i++) {
            if (isMiner(addrs[i])) {
                count = count.add(1);
            }
        }
        if (count >= sysStudioInviteMinerCount) {
            return true;
        }
        return false;
    }

    function approveStudio(address usr) public onlyOwner returns (bool) {
        require(pendingStudio.contains(usr), "address not in pending studio list");
        require(currentStudioCount < sysMaxStudioCount, "studio count exceeds max studio count");

        studioWhiteList.add(usr);
        pendingStudio.remove(usr);

        // set flag
        studioInfo[usr].approved = true;

        // set studio reward
        setStudioReward(usr, false);

        currentStudioCount = currentStudioCount.add(1);

        return true;
    }

    function rejectStudio(address usr, bytes32 _reason) public onlyOwner returns (bool) {
        require(pendingStudio.contains(usr), "address not in pending studio list");

        pendingStudio.remove(usr);
        removedStudio.add(usr);

        // set flag
        studioInfo[usr].rejected = true;
        studioInfo[usr].reason = _reason;
        return true;
    }

    function removeStudio(address usr) public onlyOwner returns (bool) {
        require(studioWhiteList.contains(usr), "address not in studio whitelist");

        studioWhiteList.remove(usr);
        removedStudio.add(usr);

        // set flag
        studioInfo[usr].approved = false;
        studioInfo[usr].rejected = true;

        // set studio reward
        setStudioReward(usr, true);

        currentStudioCount = currentStudioCount.sub(1);
        return true;
    }

    function createStudio(bytes32 _city, bytes32 _headName, bytes32 _telephone) public {
        address sender = msg.sender;
        require(isStudioQualified(sender), "not qualified");

        Studio storage studio = studioInfo[sender];
        studio.owner = minerInfo[sender].owner;
        studio.name = minerInfo[sender].name;
        studio.city = _city;
        studio.headName = _headName;
        studio.telephone = _telephone;
        studio.approved = false;
        studio.rejected = false;

        pendingStudio.add(sender);
    }

    function addMinerByOwner(address _usr, bytes32 _name) public onlyOwner {
        require(!isMiner(_usr), "account is already miner");

        // create miner
        Miner storage miner = minerInfo[_usr];
        miner.id = getNewMinerID();
        miner.owner = _usr;
        miner.name = _name;
        miner.lpAmount = 0;
        miner.totalAddress = 0;
        miner.whitelist = true;

        // update miner count
        currentMinerCount = currentMinerCount.add(1);

        // add miner whitelist
        minerWhiteList.add(_usr);

        // set miner reward
        setMinerFHBReward(_usr);
}

    function addStudioByOwner(address _usr, bytes32 _name) public onlyOwner {
        require(address(0) != _usr, "can't add address zero");
        require(currentStudioCount < sysMaxStudioCount, "studio count exceeds max studio count");

        // create miner
        if (!isMiner(_usr)) {
            Miner storage miner = minerInfo[_usr];
            miner.id = getNewMinerID();
            miner.owner = _usr;
            miner.name = _name;
            miner.lpAmount = 0;
            miner.totalAddress = 0;

            // update miner count
            currentMinerCount = currentMinerCount.add(1);

            minerWhiteList.add(_usr);

            // set miner reward
            setMinerFHBReward(_usr);
        }

        // create studio
        Studio storage studio = studioInfo[_usr];
        if (address(0) == studio.owner) {
            studio.owner = _usr;
            studio.name = _name;
            studio.approved = true;
            studio.rejected = false;

            // add studio whitelist
            studioWhiteList.add(_usr);

            // update studio count
            currentStudioCount = currentStudioCount.add(1);

            // set studio reward
            setStudioReward(_usr, false);
        }
    }

    function setStudioReward(address usr, bool remove) internal {
        if (remove) {
            studioReward[usr] = 0;
        } else {
            studioReward[usr] = STUDIO_EXTRA_KOT_REWARD;
        }
    }

    function getPendingStudio(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return pendingStudio.getPage(index, pageSize);
    }

    function getStudioWhiteList(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return studioWhiteList.getPage(index, pageSize);
    }

    function getRemovedStudio(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return removedStudio.getPage(index, pageSize);
    }

    function getMinerWhiteList(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return minerWhiteList.getPage(index, pageSize);
    }

    function updateLPPool() public {
        if (block.timestamp <= sysStartTime) { // not start
            return;
        }

        uint256 lpSupply = ITRC20(lp).balanceOf(address(this));
        if (lpSupply == 0) { // no lp
            lpPoolInfo.lastRewardTime = block.timestamp;
            return;
        }

        PoolInfo memory lpPool = lpPoolInfo;

        uint256 secds = block.timestamp.sub(lpPoolInfo.lastRewardTime);

        // FHB reward
        if (lpPool.lastRewardTime < sysFhbMiningEndTime && lpPool.totalRewardFHB < sysLPPoolMaxFHBReward) {
            uint256 fhbReward = secds.mul(sysLPPoolFHBPerSecond);
            uint256 delta = sysLPPoolMaxFHBReward.sub(lpPool.totalRewardFHB);
            lpPool.totalRewardFHB = lpPool.totalRewardFHB.add(fhbReward);
            if (lpPool.totalRewardFHB >= sysLPPoolMaxFHBReward) { // upper limit
                fhbReward = delta;
                lpPool.totalRewardFHB = sysLPPoolMaxFHBReward;
            }
            lpPool.accFHBPerShare = lpPool.accFHBPerShare.add(
                fhbReward.mul(ACC_PRECISION).div(lpSupply)
            );
        }

        // KOT reward
        if (lpPool.lastRewardTime < sysKotMiningEndTime && lpPool.totalRewardKOT < sysLPPoolMaxKOTReward) {
            uint256 kotReward = secds.mul(sysLPPoolKOTPerSecond);
            uint256 delta = sysLPPoolMaxKOTReward.sub(lpPool.totalRewardKOT);
            lpPool.totalRewardKOT = lpPool.totalRewardKOT.add(kotReward);
            if (lpPool.totalRewardKOT >= sysLPPoolMaxKOTReward) { // upper limit
                kotReward = delta;
                lpPool.totalRewardKOT = sysLPPoolMaxKOTReward;
            }
            lpPool.accKOTPerShare = lpPool.accKOTPerShare.add(
                kotReward.mul(ACC_PRECISION).div(lpSupply)
            );
        }

        // update lastRewardTime
        lpPool.lastRewardTime = block.timestamp;

        lpPoolInfo = lpPool;
    }

    function updateKOTPool() public {
        if (block.timestamp <= sysStartTime) { // not start
            return;
        }

        if (kotTotalStaking == 0) { // no kot
            kotPoolInfo.lastRewardTime = block.timestamp;
            return;
        }

        // for gas saving
        PoolInfo memory kotPool = kotPoolInfo;

        uint256 secds = block.timestamp.sub(kotPoolInfo.lastRewardTime);

        // FHB reward
        if (kotPool.lastRewardTime < sysFhbMiningEndTime) {
            uint256 fhbReward = secds.mul(sysKOTPoolFHBPerSecond);
            uint256 delta = sysKOTPoolMaxFHBReward.sub(kotPool.totalRewardFHB);
            kotPool.totalRewardFHB = kotPool.totalRewardFHB.add(fhbReward);
            if (kotPool.totalRewardFHB >= sysKOTPoolMaxFHBReward) { // upper limit
                fhbReward = delta;
                kotPool.totalRewardFHB = sysKOTPoolMaxFHBReward;
            }
            kotPool.accFHBPerShare = kotPool.accFHBPerShare.add(
                fhbReward.mul(ACC_PRECISION).div(kotTotalStaking)
            );
        }

        // KOT reward
        if (kotPool.lastRewardTime < sysKotMiningEndTime) {
            uint256 kotReward = secds.mul(sysKOTPoolKOTPerSecond);
            uint256 delta = sysKOTPoolMaxKOTReward.sub(kotPool.totalRewardKOT);
            kotPool.totalRewardKOT = kotPool.totalRewardKOT.add(kotReward);
            if (kotPool.totalRewardKOT >= sysKOTPoolMaxKOTReward) { // upper limit
                kotReward = delta;
                kotPool.totalRewardKOT = sysKOTPoolMaxKOTReward;
            }
            kotPool.accKOTPerShare = kotPool.accKOTPerShare.add(
                kotReward.mul(ACC_PRECISION).div(kotTotalStaking)
            );
        }

        // update lastRewardTime
        kotPool.lastRewardTime = block.timestamp;

        // set kotPoolInfo
        kotPoolInfo = kotPool;
    }

    function pendingKOTReward(address _usr) public view returns (uint256) {
        UserInfo memory info = userInfo[_usr];
        PoolInfo memory lpPoolInfox = lpPoolInfo;
        PoolInfo memory kotPoolInfox = kotPoolInfo;

        if (block.timestamp <= sysStartTime) { // not start
            return 0;
        }

        if (lpPoolInfox.lastRewardTime == 0) {
            lpPoolInfox.lastRewardTime = block.timestamp;
        }
        if (kotPoolInfox.lastRewardTime == 0) {
            kotPoolInfox.lastRewardTime = block.timestamp;
        }

        uint256 secds = block.timestamp.sub(lpPoolInfox.lastRewardTime);

        // update LP pool
        uint256 lpSupply = ITRC20(lp).balanceOf(address(this));
        if (lpSupply > 0) {
            if (lpPoolInfox.lastRewardTime < sysKotMiningEndTime && lpPoolInfox.totalRewardKOT < sysLPPoolMaxKOTReward) {
                uint256 kotReward = secds.mul(sysLPPoolKOTPerSecond);
                uint256 delta = sysLPPoolMaxKOTReward.sub(lpPoolInfox.totalRewardKOT);
                lpPoolInfox.totalRewardKOT = lpPoolInfox.totalRewardKOT.add(kotReward);
                if (lpPoolInfox.totalRewardKOT >= sysLPPoolMaxKOTReward) { // upper limit
                    kotReward = delta;
                }
                lpPoolInfox.accKOTPerShare = lpPoolInfox.accKOTPerShare.add(
                    kotReward.mul(ACC_PRECISION).div(lpSupply)
                );
            }
        }

        // update KOT pool
        if (kotTotalStaking > 0) {
            if (kotPoolInfox.lastRewardTime < sysKotMiningEndTime) {
                uint256 kotReward = secds.mul(sysKOTPoolKOTPerSecond);
                uint256 delta = sysKOTPoolMaxKOTReward.sub(kotPoolInfox.totalRewardKOT);
                kotPoolInfox.totalRewardKOT = kotPoolInfox.totalRewardKOT.add(kotReward);
                if (kotPoolInfo.totalRewardKOT >= sysKOTPoolMaxKOTReward) { // upper limit
                    kotReward = delta;
                }
                kotPoolInfox.accKOTPerShare = kotPoolInfox.accKOTPerShare.add(
                    kotReward.mul(ACC_PRECISION).div(kotTotalStaking)
                );
            }
        }

        if (info.kotAmount > 0) {
            // KOT reward
            uint256 pendingKOT = info.kotAmount.mul(kotPoolInfox.accKOTPerShare).div(ACC_PRECISION).sub(info.rewardDebtKot);
            info.reward = info.reward.add(pendingKOT);
        }

        if (info.lpAmount > 0) {
            // KOT reward
            uint256 pendingKOT = info.lpAmount.mul(lpPoolInfox.accKOTPerShare).div(ACC_PRECISION).sub(info.rewardDebtLP);
            info.reward = info.reward.add(pendingKOT);
        }

        uint256 total = info.reward.add(inviteReward[_usr]).add(studioReward[_usr]);
        return total;
    }

    function pendingFHBReward(address _usr) public view returns (uint256) {
        UserInfo memory info = userInfo[_usr];
        PoolInfo memory lpPoolInfox = lpPoolInfo;
        PoolInfo memory kotPoolInfox = kotPoolInfo;

        if (block.timestamp <= sysStartTime) { // not start
            return 0;
        }

        if (lpPoolInfox.lastRewardTime == 0) {
            lpPoolInfox.lastRewardTime = block.timestamp;
        }
        if (kotPoolInfox.lastRewardTime == 0) {
            kotPoolInfox.lastRewardTime = block.timestamp;
        }

        uint256 secds = block.timestamp.sub(lpPoolInfox.lastRewardTime);

        // update LP pool
        uint256 lpSupply = ITRC20(lp).balanceOf(address(this));
        if (lpSupply > 0) {
            if (lpPoolInfox.lastRewardTime < sysFhbMiningEndTime && lpPoolInfox.totalRewardFHB < sysLPPoolMaxFHBReward) {
                uint256 fhbReward = secds.mul(sysLPPoolFHBPerSecond);
                uint256 delta = sysLPPoolMaxFHBReward.sub(lpPoolInfox.totalRewardFHB);
                lpPoolInfox.totalRewardFHB = lpPoolInfox.totalRewardFHB.add(fhbReward);
                if (lpPoolInfox.totalRewardFHB >= sysLPPoolMaxFHBReward) { // upper limit
                    fhbReward = delta;
                }
                lpPoolInfox.accFHBPerShare = lpPoolInfox.accFHBPerShare.add(
                    fhbReward.mul(ACC_PRECISION).div(lpSupply)
                );
            }
        }

        // update KOT pool
        if (kotTotalStaking > 0) {
            if (kotPoolInfox.lastRewardTime < sysFhbMiningEndTime) {
                uint256 fhbReward = secds.mul(sysKOTPoolFHBPerSecond);
                uint256 delta = sysKOTPoolMaxFHBReward.sub(kotPoolInfox.totalRewardFHB);
                kotPoolInfox.totalRewardFHB = kotPoolInfox.totalRewardFHB.add(fhbReward);
                if (kotPoolInfox.totalRewardFHB >= sysKOTPoolMaxFHBReward) { // upper limit
                    fhbReward = delta;
                }
                kotPoolInfox.accFHBPerShare = kotPoolInfox.accFHBPerShare.add(
                    fhbReward.mul(ACC_PRECISION).div(kotTotalStaking)
                );
            }
        }

        if (info.kotAmount > 0) {
            // FHB reward
            uint256 pendingFHB = info.kotAmount.mul(kotPoolInfox.accFHBPerShare).div(ACC_PRECISION).sub(info.rewardDebtFHBKot);
            info.rewardFHB = info.rewardFHB.add(pendingFHB);
        }

        if (info.lpAmount > 0) {
            // FHB reward
            uint256 pendingFHB = info.lpAmount.mul(lpPoolInfox.accFHBPerShare).div(ACC_PRECISION).sub(info.rewardDebtFHBLP);
            info.rewardFHB = info.rewardFHB.add(pendingFHB);
        }

        uint256 total = info.rewardFHB.add(minerFHBReward[_usr]);
        return total;
    }

    function stakeLP(uint256 _amount, address _inviter) public {
        require(block.timestamp < sysKotMiningEndTime, "staking time end");

        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];

        updateLPPool();

        // update reward
        if (user.lpAmount > 0) {
            // KOT reward
            uint256 pendingKOT =
                user.lpAmount.mul(lpPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtLP);
            user.reward = user.reward.add(pendingKOT);

            // inviter reward
            addInviteReward(getInviter(sender), pendingKOT);

            // FHB reward
            uint256 pendingFHB =
                user.lpAmount.mul(lpPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBLP);
            user.rewardFHB = user.rewardFHB.add(pendingFHB);
        }

        // transfer LP
        TransferHelper.safeTransferFrom(lp, sender, address(this), _amount);

        // add inviter
        refer.submitInviter(sender, _inviter);

        // update staking info
        user.lpAmount = user.lpAmount.add(_amount);
        user.rewardDebtLP = user.lpAmount.mul(lpPoolInfo.accKOTPerShare).div(ACC_PRECISION);
        user.rewardDebtFHBLP = user.lpAmount.mul(lpPoolInfo.accFHBPerShare).div(ACC_PRECISION);

        if (user.vestingKOTStart == 0) {
            user.vestingKOTStart = block.timestamp + 90 days;
        }

        if (user.vestingFHBStart == 0) {
            user.vestingFHBStart = block.timestamp + 30 days;
        }

         emit StakeLP(sender, _amount);
    }

    function unstakeLP() public {
        require(block.timestamp >= sysKotMiningEndTime, "unstake time not start");

        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];

        updateLPPool();

        // for gas saving
        uint256 lpAmount = user.lpAmount;

        if (lpAmount <= 0) {
            return;
        }

        // update KOT reward
        uint256 pendingKOT = lpAmount.mul(lpPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtLP);
        user.reward = user.reward.add(pendingKOT);

        // inviter reward
        addInviteReward(getInviter(sender), pendingKOT);

        // FHB reward
        uint256 pendingFHB = lpAmount.mul(lpPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBLP);
        user.rewardFHB = user.rewardFHB.add(pendingFHB);

        // withdraw LP
        TransferHelper.safeTransfer(lp, sender, lpAmount);

        // update lp stake info
        user.lpAmount = 0;
        user.rewardDebtLP = 0;
        user.rewardDebtFHBLP = 0;

        emit UnStakeLP(sender, lpAmount);
    }

    function addInviteReward(address usr, uint256 amount) internal {
        if (usr == address(0)) {
            return;
        }
        if (totalInviteReward >= INVITE_POOL_MAX_REWARD) { // upper limit
            return;
        }

        uint256 reward = amount.mul(sysInviteRewardPercent).div(100);
        uint256 delta = INVITE_POOL_MAX_REWARD.sub(totalInviteReward);
        totalInviteReward = totalInviteReward.add(reward);
        if (totalInviteReward >= INVITE_POOL_MAX_REWARD) {
            totalInviteReward = INVITE_POOL_MAX_REWARD;
            reward = delta;
        }

        inviteReward[usr] = inviteReward[usr].add(reward);
    }

    function stakeKOT(uint256 _amount, address _inviter) public {
        require(block.timestamp < sysKotMiningEndTime, "staking time end");

        UserInfo storage user = userInfo[msg.sender];
        updateKOTPool();
        // update reward
        if (user.kotAmount > 0) {
            // KOT reward
            uint256 pendingKOT = user.kotAmount.mul(kotPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtKot);
            user.reward = user.reward.add(pendingKOT);

            // inviter reward
            addInviteReward(getInviter(msg.sender), pendingKOT);

            // FHB reward
            uint256 pendingFHB = user.kotAmount.mul(kotPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBKot);
            user.rewardFHB = user.rewardFHB.add(pendingFHB);
        }

        // transfer KOT
        TransferHelper.safeTransferFrom(kot, address(msg.sender), address(this), _amount);

        // add inviter
        refer.submitInviter(msg.sender, _inviter);

        // update staking info
        user.kotAmount = user.kotAmount.add(_amount);
        user.rewardDebtKot = user.kotAmount.mul(kotPoolInfo.accKOTPerShare).div(ACC_PRECISION);
        user.rewardDebtFHBKot = user.kotAmount.mul(kotPoolInfo.accFHBPerShare).div(ACC_PRECISION);

        // update total kot staked
        kotTotalStaking = kotTotalStaking.add(_amount);

        // set user vesting start time
        if (user.vestingKOTStart == 0) {
            user.vestingKOTStart = block.timestamp + 90 days;
        }
        if (user.vestingFHBStart == 0) {
            user.vestingFHBStart = block.timestamp + 30 days;
        }

        emit StakeKOT(msg.sender, _amount);
   }

    function unstake() public {
        unstakeKOT();
        unstakeLP();
    }

    function unstakeKOT() public {
        require(block.timestamp >= sysKotMiningEndTime, "unstake time not start");

        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];

        updateKOTPool();

        // for gas saving
        uint256 kotAmount = user.kotAmount;
        if (kotAmount <= 0) {
            return;
        }

        // KOT reward
        uint256 pendingKOT = kotAmount.mul(kotPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtKot);
        user.reward = user.reward.add(pendingKOT);

        // inviter reward
        addInviteReward(getInviter(sender), pendingKOT);

        // FHB reward
        uint256 pendingFHB = kotAmount.mul(kotPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBKot);
        user.rewardFHB = user.rewardFHB.add(pendingFHB);

        // withdraw KOT
        TransferHelper.safeTransfer(kot, address(sender), user.kotAmount);

        // 更新质押
        user.kotAmount = 0;
        user.rewardDebtKot = 0;
        user.rewardDebtFHBKot = 0;

        // 更新质押的KOT总数量
        kotTotalStaking = kotTotalStaking.sub(kotAmount);

        emit UnStakeKOT(sender, kotAmount);
    }

    // update user mining reward
    function harvest() public {
        UserInfo storage user = userInfo[msg.sender];

        updateLPPool();
        updateKOTPool();

        // update kot staking reward
        if (user.kotAmount > 0) {
            uint256 pendingKOT =
                user.kotAmount.mul(kotPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtKot);
            user.reward = user.reward.add(pendingKOT);
            user.rewardDebtKot = user.kotAmount.mul(kotPoolInfo.accKOTPerShare).div(ACC_PRECISION);

            uint256 pendingFHB =
                user.kotAmount.mul(kotPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBKot);
            user.rewardFHB = user.rewardFHB.add(pendingFHB);
            user.rewardDebtFHBKot = user.kotAmount.mul(kotPoolInfo.accFHBPerShare).div(ACC_PRECISION);

            // update invite reward
            addInviteReward(getInviter(msg.sender), pendingKOT);
        }

        // update LP staking reward
        if (user.lpAmount > 0) {
            uint256 pendingKOT =
                user.lpAmount.mul(lpPoolInfo.accKOTPerShare).div(ACC_PRECISION).sub(user.rewardDebtLP);
            user.reward = user.reward.add(pendingKOT);
            user.rewardDebtLP = user.lpAmount.mul(lpPoolInfo.accKOTPerShare).div(ACC_PRECISION);

            uint256 pendingFHB =
                user.lpAmount.mul(lpPoolInfo.accFHBPerShare).div(ACC_PRECISION).sub(user.rewardDebtFHBLP);
            user.rewardFHB = user.rewardFHB.add(pendingFHB);
            user.rewardDebtFHBLP = user.lpAmount.mul(lpPoolInfo.accFHBPerShare).div(ACC_PRECISION);

            // update invite reward
            addInviteReward(getInviter(msg.sender), pendingKOT);
        }
    }

    // withdraw KOT reward
    function withdrawKOTReward() public {
        harvest();
        // unstake();
        releaseKOT(msg.sender);
    }

    // withdraw FHB reward
    function withdrawFHBReward() public {
        harvest();
        releaseFHB(msg.sender);
    }

    // withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        TransferHelper.safeTransfer(lp, msg.sender, user.lpAmount);
        TransferHelper.safeTransfer(kot, msg.sender, user.kotAmount);

        emit EmergencyWithdraw(msg.sender, 1, user.lpAmount);
        emit EmergencyWithdraw(msg.sender, 0, user.kotAmount);

        user.lpAmount = 0;
        user.kotAmount = 0;
        user.rewardDebtLP = 0;
        user.rewardDebtKot = 0;
    }

    function isMiner(address usr) public view returns (bool) {
        if (minerInfo[usr].id > 0) {
            return true;
        }
        return false;
    }

    function createMiner(bytes32 name) public returns (bool) {
        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];
        require(user.lpAmount >= sysMinerMinLPStaked, "user staking LP insufficient");

        Miner storage miner = minerInfo[sender];
        require(miner.id <= 0, "only can create one miner");

        miner.id = getNewMinerID();
        miner.owner = sender;
        miner.name = name;
        miner.lpAmount = getInviteLPAmount(sender);
        miner.totalAddress = getInviteLength(sender);

        // update miner rank by lp staked
        updateRank(sender, miner.lpAmount);

        // update miner count
        currentMinerCount = currentMinerCount.add(1);

        // set miner FHB reward
        setMinerFHBReward(sender);

        return true;
    }

    function setMinerFHBReward(address usr) internal {
        if (currentMinerCount > sysMaxMinerCountWithFHBReward) {
            return;
        }
        minerFHBReward[usr] = MINER_EXTRA_FHB_REWARD;
    }

    function updateMinerRank(address usr) public returns (bool) {
        require(isMiner(usr), "not miner");

        Miner storage miner = minerInfo[usr];
        miner.lpAmount = getInviteLPAmount(usr);
        miner.totalAddress = getInviteLength(usr);

        // update miner rank by lp staked
        updateRank(usr, miner.lpAmount);

        return true;
    }

    // get a newer auto increased id
    function getNewMinerID() internal returns (uint256) {
        minerID = minerID.add(1);
        return minerID;
    }

    // get inviter
    function getInviter(address usr) public view returns (address) {
        return refer.getInviter(usr);
    }

    // get invite list
    function getInviteList(address inviter) public view returns (address[] memory) {
        uint256 len = getInviteLength(inviter);
        address[] memory addrs = new address[](len);
        for(uint256 i = 0; i < len; i++) {
            addrs[i] = refer.inviteList(inviter, i);
        }
        return addrs;
    }

    function getInviteLPAmount(address inviter) public view returns (uint256) {
        address[] memory addrs = getInviteList(inviter);
        uint256 total = userInfo[inviter].lpAmount;
        for (uint256 i = 0; i < addrs.length; i++) {
            uint256 amount = userInfo[addrs[i]].lpAmount;
            total = total.add(amount);
        }
        return total;
    }

    // get invite address count
    function getInviteLength(address inviter) public view returns (uint256) {
        return refer.getInviteLength(inviter);
    }

    // get top K miners
    function getTopKMiners(uint256 k) public view returns (address[] memory) {
        return getTop(k);
    }

    /////////////////////////////////////////////////////////////
    // Linear Vesting functions
    /////////////////////////////////////////////////////////////
    function releaseKOT(address addr) public {
        UserInfo storage user = userInfo[addr];

        uint256 unreleased = getReleasableKOT(addr);
        if (unreleased <= 0) {
            return;
        }

        user.released = user.released.add(unreleased);
        TransferHelper.safeTransfer(kot, addr, unreleased);

        emit VestingKOTReleased(addr, unreleased);
    }

    function getReleasableKOT(address addr) public view returns (uint256) {
        UserInfo storage user = userInfo[addr];
        uint256 totalReward = getUserTotalKOTReward(addr);
        if (totalReward <= 0) {
            return 0;
        }
        return getVestedKOT(addr).sub(user.released);
    }

    function getVestedKOT(address addr) public view returns (uint256) {
        uint256 totalReward = getUserTotalKOTReward(addr);
        if (totalReward <= 0) {
            return 0;
        }

        uint256 vestingStart = userInfo[addr].vestingKOTStart;

        if (block.timestamp <= vestingStart) {
            return 0;
        } else if (block.timestamp >= vestingStart.add(sysVestingKOTDuration)) {
            return totalReward;
        } else {
            return totalReward.mul(block.timestamp.sub(vestingStart)).div(sysVestingKOTDuration);
        }
    }

    function getReleasedKOT(address usr) public view returns (uint256) {
        return userInfo[usr].released;
    }

    function releaseFHB(address addr) public {
        UserInfo storage user = userInfo[addr];

        uint256 unreleased = getReleasableFHB(addr);
        if (unreleased <= 0) {
            return;
        }

        user.releasedFHB = user.releasedFHB.add(unreleased);
        TransferHelper.safeTransfer(fhb, addr, unreleased);

        emit VestingFHBReleased(addr, unreleased);
    }

    function getReleasableFHB(address addr) public view returns (uint256) {
        UserInfo storage user = userInfo[addr];
        uint256 reward = getUserTotalFHBReward(addr);
        if (reward <= 0) {
            return 0;
        }
        return getVestedFHB(addr).sub(user.releasedFHB);
    }

    function getVestedFHB(address addr) public view returns (uint256) {
        uint256 reward = getUserTotalFHBReward(addr);
        if (reward <= 0) {
            return 0;
        }

        uint256 vestingStart = userInfo[addr].vestingFHBStart;

        if (block.timestamp <= vestingStart) {
            return 0;
        } else if (block.timestamp >= vestingStart.add(sysVestingFHBDuration)) {
            return reward;
        } else {
            return reward.mul(block.timestamp.sub(vestingStart)).div(sysVestingFHBDuration);
        }
    }

    function getReleasedFHB(address usr) public view returns (uint256) {
        return userInfo[usr].releasedFHB;
    }

    /////////////////////////////////////////////////////////////


    /////////////////////////////////////////////////////////////
    // Owner funcitons
    /////////////////////////////////////////////////////////////

    function setLPPoolKotPerBlock(uint256 _value) public onlyOwner {
        sysLPPoolKOTPerSecond = _value;
    }

    function setKotPoolKotPerBlock(uint256 _value) public onlyOwner {
        sysKOTPoolKOTPerSecond = _value;
    }

    function setFHBMiningEndTime(uint256 _value) public onlyOwner {
        sysFhbMiningEndTime = _value;
    }

    function setKOTMiningEndTime(uint256 _value) public onlyOwner {
        sysKotMiningEndTime = _value;
    }

    function setUsrVestingKOTStart(address usr, uint256 _value) public onlyOwner {
        UserInfo storage info = userInfo[usr];
        info.vestingKOTStart = _value;
    }

    function setUsrVestingFHBStart(address usr, uint256 _value) public onlyOwner {
        UserInfo storage info = userInfo[usr];
        info.vestingFHBStart = _value;
    }

    function setInviteRewardPercent(uint256 _value) public onlyOwner {
        sysInviteRewardPercent = _value;
    }

    function setMinerMinLPAmount(uint256 _value) public onlyOwner {
        sysMinerMinLPStaked = _value;
    }

    function setVestingKOTDuration(uint256 _value) public onlyOwner {
        sysVestingKOTDuration = _value;
    }

    function setVestingFHBDuration(uint256 _value) public onlyOwner {
        sysVestingFHBDuration = _value;
    }

    function setMaxMinerCountWithFHBReward(uint256 _value) public onlyOwner {
        sysMaxMinerCountWithFHBReward = _value;
    }

    function setStudioInviteMinerCount(uint256 _value) public onlyOwner {
        sysStudioInviteMinerCount = _value;
    }

    function setMaxStudioCount(uint256 _value) public onlyOwner {
        sysMaxStudioCount = _value;
    }

    function setKOT(address _kot) public onlyOwner  returns (bool) {
        kot = _kot;
        return true;
    }

    function setLP(address _lp) public onlyOwner  returns (bool) {
        lp = _lp;
        return true;
    }

    function setRefer(Refer _refer) public onlyOwner  returns (bool) {
        refer = _refer;
        return true;
    }

    function updateSysRewardPerSecond() public onlyOwner {
        sysLPPoolKOTPerSecond = sysLPPoolMaxKOTReward.div(sysKotMiningEndTime.sub(sysStartTime));
        sysKOTPoolKOTPerSecond = sysKOTPoolMaxKOTReward.div(sysKotMiningEndTime.sub(sysStartTime));

        sysLPPoolFHBPerSecond = sysLPPoolMaxFHBReward.div(sysFhbMiningEndTime.sub(sysStartTime));
        sysKOTPoolFHBPerSecond = sysKOTPoolMaxFHBReward.div(sysFhbMiningEndTime.sub(sysStartTime));
    }

    function withdrawKOT(uint256 amount) public onlyOwner returns (bool) {
        TransferHelper.safeTransfer(kot, owner(), amount);
        return true;
    }

    function withdrawFHB(uint256 amount) public onlyOwner returns (bool) {
        TransferHelper.safeTransfer(fhb, owner(), amount);
        return true;
    }

    function withdrawLP(uint256 amount) public onlyOwner returns (bool) {
        TransferHelper.safeTransfer(lp, owner(), amount);
        return true;
    }
    /////////////////////////////////////////////////////////////
}

//SourceUnit: Migrations.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}


//SourceUnit: Ownable.sol

pragma solidity 0.5.8;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor() internal {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: Pausable.sol

pragma solidity 0.5.8;

import "./Ownable.sol";

contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool public paused;

    constructor () internal {
        paused = false;
    }

    modifier WhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier WhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function Pause() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function Unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

//SourceUnit: Rank.sol

pragma solidity 0.5.8;

import "./Ownable.sol";

contract Rank is Ownable {
    mapping(address => uint256)  balances;
    mapping(address => address)  _nextAddress;
    uint256 public listSize;
    address constant GUARD = address(1);

    constructor() public {
        _nextAddress[GUARD] = GUARD;
    }

    function addRankAddress(address addr, uint256 balance) internal {
        if (_nextAddress[addr] != address(0)) {
            return;
        }

        address index = _findIndex(balance);
        balances[addr] = balance;
        _nextAddress[addr] = _nextAddress[index];
        _nextAddress[index] = addr;
        listSize++;
    }

    function removeRankAddress(address addr) internal {
        if (_nextAddress[addr] == address(0)) {
            return;
        }

        address prevAddress = _findPrevAddress(addr);
        _nextAddress[prevAddress] = _nextAddress[addr];

        _nextAddress[addr] = address(0);
        balances[addr] = 0;
        listSize--;
    }

    function isContains(address addr) internal view returns (bool) {
        return _nextAddress[addr] != address(0);
    }

    function getRank(address addr) public view returns (uint256) {
        if (!isContains(addr)) {
            return 0;
        }

        uint idx = 0;
        address currentAddress = GUARD;
        while(_nextAddress[currentAddress] != GUARD) {
            if (addr != currentAddress) {
                currentAddress = _nextAddress[currentAddress];
                idx++;
            } else {
                break;
            }
        }
        return idx;
    }

    function getRankBalance(address addr) internal view returns (uint256) {
        return balances[addr];
    }

    function getTop(uint256 k) public view returns (address[] memory) {
        if (k > listSize) {
            k = listSize;
        }

        address[] memory addressLists = new address[](k);
        address currentAddress = _nextAddress[GUARD];
        for (uint256 i = 0; i < k; ++i) {
            addressLists[i] = currentAddress;
            currentAddress = _nextAddress[currentAddress];
        }

        return addressLists;
    }

    function updateRank(address addr, uint256 newBalance) internal {
        if (!isContains(addr)) {
            // 如果不存在，则添加
            addRankAddress(addr, newBalance);
        } else {
            // 已存在，则更新
            address prevAddress = _findPrevAddress(addr);
            address nextAddress = _nextAddress[addr];
            if (_verifyIndex(prevAddress, newBalance, nextAddress)) {
                balances[addr] = newBalance;
            } else {
                removeRankAddress(addr);
                addRankAddress(addr, newBalance);
            }
        }
    }

    function _isPrevAddress(address addr, address prevAddress) internal view returns (bool) {
        return _nextAddress[prevAddress] == addr;
    }

    // 用于验证该值在左右地址之间
    // 如果 左边的值 ≥ 新值 > 右边的值将返回 true(如果我们保持降序，并且如果值等于，则新值应该在旧值的后面)
    function _verifyIndex(address prevAddress, uint256 newValue, address nextAddress)
    internal
    view
    returns (bool) {
        return (prevAddress == GUARD || balances[prevAddress] >= newValue) &&
        (nextAddress == GUARD || newValue > balances[nextAddress]);
    }

    // 用于查找新值应该插入在哪一个地址后面
    function _findIndex(uint256 newValue) internal view returns (address) {
        address candidateAddress = GUARD;
        while(true) {
            if (_verifyIndex(candidateAddress, newValue, _nextAddress[candidateAddress]))
                return candidateAddress;

            candidateAddress = _nextAddress[candidateAddress];
        }
    }

    function _findPrevAddress(address addr) internal view returns (address) {
        address currentAddress = GUARD;
        while(_nextAddress[currentAddress] != GUARD) {
            if (_isPrevAddress(addr, currentAddress))
                return currentAddress;

            currentAddress = _nextAddress[currentAddress];
        }
        return address(0);
    }
}

//SourceUnit: Refer.sol

pragma solidity 0.5.8;

import "./AddressSetLib.sol";

contract Refer {
    using AddressSetLib for AddressSetLib.AddressSet;

    mapping (address => address) public inviters;
    mapping (address => address[]) public inviteList;

    AddressSetLib.AddressSet internal addressSet;


    function submitInviter(address usr, address inviter) public returns (bool) {
        require(usr == tx.origin, "usr must be tx origin");

        if (inviters[usr] == address(0)) {
            inviters[usr] = inviter;

            addressSet.add(inviter);

            if (!isReferContains(usr, inviter)) {
                inviteList[inviter].push(usr);
            }
        }
        return true;
    }

    function getInviteLength(address inviter) public view returns (uint256) {
        return inviteList[inviter].length;
    }

    function isReferContains(address usr, address inviter) public view returns (bool) {
        address[] memory addrList = inviteList[inviter];
        bool found = false;
        for (uint256 i = 0; i < addrList.length; i++) {
            if (usr == addrList[i]) {
                found = true;
                break;
            }
        }
        return found;
    }

    function getInviter(address usr) public view returns (address) {
        return inviters[usr];
    }

    function getInviters(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return addressSet.getPage(index, pageSize);
    }
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;

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

//SourceUnit: TransferHelper.sol

pragma solidity 0.5.8;

// helper methods for interacting with TRC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, ) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, ) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferTRX(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}

//SourceUnit: lpToken.sol

pragma solidity 0.5.8;

import './ERC20Detailed.sol';

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract lpToken is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("KOT-TRX-LP", "KOT-TRX-LP", 6) {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}