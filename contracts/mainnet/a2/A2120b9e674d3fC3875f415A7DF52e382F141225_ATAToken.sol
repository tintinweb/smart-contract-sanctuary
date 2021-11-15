// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract ATAToken is ERC20, Ownable {
    using SafeMath for uint256;

    enum VestingCategory {
        EARLY_CONTRIBUTORS,
        NETWORK_FEES,
        PROTOCOL_RESERVE,
        PARTNER_ADVISORS,
        TEAM,
        ECOSYSTEM_COMMUNITY
    }

    enum VestingType {TIME, BLOCK}

    uint256 private constant TOTAL_QUOTA = 100;

    uint256 private EARLY_CONTRIBUTORS_QUOTA = 15;
    uint256 private NETWORK_FEES_QUOTA = 0;
    uint256 private PROTOCOL_RESERVE_QUOTA = 35;
    uint256 private PARTNER_ADVISORS_QUOTA = 5;
    uint256 private TEAM_QUOTA = 15;
    uint256 private ECOSYSTEM_COMMUNITY_QUOTA = 30;

    event VestingPlanAdded(uint256 uniqueId);
    event VestingPlanRevoked(uint256 uniqueId);
    event QuotaAdjusted(
        uint256 earlyContributors,
        uint256 networkFees,
        uint256 protocolReserve,
        uint256 parternerAndAdvisor,
        uint256 team,
        uint256 ecosystemAndCommunity
    );
    event Withdraw(address beneficiary, uint256 amount);

    struct VestingPlan {
        uint256 uniqueId; //each vesting plan has a unique id
        bool isRevocable; //true if the vesting plan is revocable
        bool isRevoked; //true if the vesting plan is revoked
        bool accumulateDuringCliff; //true if the token amount is accumulated during cliff
        uint256 startTime; //grant start date, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK)
        uint256 cliffDuration; //duration of cliff, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK)
        uint256 duration; //duration of vesting plan, in seconds(VestingType.TIME) or block nums(VestingType.BLOCK), exclude cliff
        uint256 interval; //release interval, in seconds, useless if vestingType is VestingType.BLOCK
        uint256 initialAmount; //amount of tokens which will be released at startTime
        uint256 totalAmount; //total amount of vesting plan
        address beneficiary; //address that benefit from the vesting plan
        VestingCategory category; //vesting plan category -e.g. for backers, for team members...
        VestingType vestingType; //vesting type, vestingType==VestingType.BLOCK indicates that use block num as timing unit
    }

    mapping(uint256 => VestingPlan) private _vestingPlans;
    mapping(address => uint256[]) private _vestingPlanIds;
    mapping(uint256 => uint256) private _released;
    mapping(uint32 => uint256) private _categoryVestedAmount;

    constructor(uint256 initialSupply) public ERC20('Automata', 'ATA') {
        _mint(msg.sender, initialSupply);
    }

    function addVestingPlan(
        address beneficiary,
        uint256 totalAmount,
        uint256 initialAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration,
        uint256 interval,
        bool accumulateDuringCliff,
        bool isRevocable,
        VestingCategory category,
        VestingType vestingType
    ) public onlyOwner {
        uint256 currentTime = (vestingType == VestingType.TIME ? now : block.number);
        //check the startTime
        require(startTime > currentTime, 'The start time can not be earlier than the current time');
        require(initialAmount <= totalAmount, 'Initial amount can not be greater than the total amount');
        //check whether owner's balance is enough
        require(balanceOf(owner()) >= totalAmount, "Exceed owner's balance");
        //check whether category's balance is enough
        require(
            (_categoryVestedAmount[uint32(category)] + totalAmount) <=
                totalSupply().mul(_getCategoryPercentage(category)).div(TOTAL_QUOTA),
            "Exceed category's balance"
        );

        //generate unique id for vesting plan
        uint256 uniqueId = _getUniqueId(beneficiary);
        _vestingPlanIds[beneficiary].push(uniqueId);
        _vestingPlans[uniqueId] = VestingPlan(
            uniqueId,
            isRevocable,
            false,
            accumulateDuringCliff,
            startTime,
            cliffDuration,
            duration,
            interval,
            initialAmount,
            totalAmount,
            beneficiary,
            category,
            vestingType
        );
        _categoryVestedAmount[uint32(category)] = _categoryVestedAmount[uint32(category)] + totalAmount;
        //deposit funds in address(this)
        transfer(address(this), totalAmount);
        emit VestingPlanAdded(uniqueId);
    }

    /**
        revoke all vesting plan of `beneficiary`
     */
    function revokeVestingPlan(uint256 uniqueId) public onlyOwner {
        VestingPlan storage plan = _vestingPlans[uniqueId];
        require(plan.uniqueId == uniqueId, 'Vesting plan not exist');

        require(plan.isRevoked == false, "Vesting plan is already revoked");
        require(plan.isRevocable, 'Vesting plan is not revocable');

        plan.isRevoked = true;

        uint256 unreleasedAmount = _getUnreleasedAmount(uniqueId);
        //refund the unreleased tokens to owner
        this.transfer(owner(), unreleasedAmount);
        emit VestingPlanRevoked(uniqueId);
    }

    function getVestingPlan(uint256 planUniqueId)
        public
        view
        onlyOwner
        returns (
            bool isRevocable,
            bool isRevoked,
            bool accumulateDuringCliff,
            uint256 startTime,
            uint256 cliffDuration,
            uint256 duration,
            uint256 interval,
            uint256 initialAmount,
            uint256 totalAmount,
            address beneficiary,
            VestingCategory category,
            VestingType vestingType
        )
    // VestingType vestingType
    {
        VestingPlan memory vestingPlan = _vestingPlans[planUniqueId];
        return (
            vestingPlan.isRevocable,
            vestingPlan.isRevoked,
            vestingPlan.accumulateDuringCliff,
            vestingPlan.startTime,
            vestingPlan.cliffDuration,
            vestingPlan.duration,
            vestingPlan.interval,
            vestingPlan.initialAmount,
            vestingPlan.totalAmount,
            vestingPlan.beneficiary,
            vestingPlan.category,
            vestingPlan.vestingType
        );
    }

    function adjustQuota(
        uint256 earlyContributors,
        uint256 networkFees,
        uint256 protocolReserve,
        uint256 parternerAndAdvisor,
        uint256 team,
        uint256 ecosystemAndCommunity
    ) public onlyOwner {
        require(
            earlyContributors + networkFees + protocolReserve + parternerAndAdvisor + team + ecosystemAndCommunity ==
                100,
            'Invalid quota'
        );

        uint256 totalSupply = totalSupply();

        require(
            _categoryVestedAmount[uint32(VestingCategory.EARLY_CONTRIBUTORS)] <=
                totalSupply.mul(earlyContributors).div(TOTAL_QUOTA),
            'Exceed allocated quota, EARLY_CONTRIBUTORS'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.NETWORK_FEES)] <=
                totalSupply.mul(networkFees).div(TOTAL_QUOTA),
            'Exceed allocated quota, NETWORK_FEES'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.PROTOCOL_RESERVE)] <=
                totalSupply.mul(protocolReserve).div(TOTAL_QUOTA),
            'Exceed allocated quota, PROTOCOL_RESERVE'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.PARTNER_ADVISORS)] <=
                totalSupply.mul(parternerAndAdvisor).div(TOTAL_QUOTA),
            'Exceed allocated quota, PARTNER_ADVISORS'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.TEAM)] <= totalSupply.mul(team).div(TOTAL_QUOTA),
            'Exceed allocated quota, TEAM'
        );

        require(
            _categoryVestedAmount[uint32(VestingCategory.ECOSYSTEM_COMMUNITY)] <=
                totalSupply.mul(ecosystemAndCommunity).div(TOTAL_QUOTA),
            'Exceed allocated quota, ECOSYSTEM_COMMUNITY'
        );

        EARLY_CONTRIBUTORS_QUOTA = earlyContributors;
        NETWORK_FEES_QUOTA = networkFees;
        PROTOCOL_RESERVE_QUOTA = protocolReserve;
        PARTNER_ADVISORS_QUOTA = parternerAndAdvisor;
        TEAM_QUOTA = team;
        ECOSYSTEM_COMMUNITY_QUOTA = ecosystemAndCommunity;

        emit QuotaAdjusted(
            earlyContributors,
            networkFees,
            protocolReserve,
            parternerAndAdvisor,
            team,
            ecosystemAndCommunity
        );
    }

    /**
        withdraw releaseable tokens
     */
    function withdraw() public {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalWithdrawableAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            uint256 vestingPlanId = vestingPlanIds[i];
            uint256 planWithdrawableAmount = _calculateWithdrawableAmount(_vestingPlans[vestingPlanId]);
            _released[vestingPlanId] = _released[vestingPlanId] + planWithdrawableAmount;
            totalWithdrawableAmount += planWithdrawableAmount;
        }

        //transfer withdrawable tokens to beneficiary
        this.transfer(msg.sender, totalWithdrawableAmount);
        emit Withdraw(msg.sender, totalWithdrawableAmount);
    }

    function getTotalVestedAmount() public view returns (uint256) {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalVestedAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            VestingPlan memory vestingPlan = _vestingPlans[vestingPlanIds[i]];
            if (!vestingPlan.isRevoked) {
                totalVestedAmount += vestingPlan.totalAmount;
            }
        }

        return totalVestedAmount;
    }

    function getWithdrawableAmount() public view returns (uint256) {
        uint256[] memory vestingPlanIds = _vestingPlanIds[msg.sender];
        require(vestingPlanIds.length != 0, 'No vesting plans exist');

        uint256 totalWithdrawableAmount = 0;
        for (uint32 i = 0; i < vestingPlanIds.length; i++) {
            uint256 planWithdrawableAmount = _calculateWithdrawableAmount(_vestingPlans[vestingPlanIds[i]]);
            totalWithdrawableAmount += planWithdrawableAmount;
        }

        return totalWithdrawableAmount;
    }

    function _getCategoryPercentage(VestingCategory category) private view returns (uint256) {
        if (category == VestingCategory.EARLY_CONTRIBUTORS) {
            return EARLY_CONTRIBUTORS_QUOTA;
        } else if (category == VestingCategory.NETWORK_FEES) {
            return NETWORK_FEES_QUOTA;
        } else if (category == VestingCategory.PROTOCOL_RESERVE) {
            return PROTOCOL_RESERVE_QUOTA;
        } else if (category == VestingCategory.PARTNER_ADVISORS) {
            return PARTNER_ADVISORS_QUOTA;
        } else if (category == VestingCategory.TEAM) {
            return TEAM_QUOTA;
        } else if (category == VestingCategory.ECOSYSTEM_COMMUNITY) {
            return ECOSYSTEM_COMMUNITY_QUOTA;
        } else {
            revert('Invalid vesting category');
        }
    }

    function _getUniqueId(address beneficiary) private view returns (uint256) {
        uint256 uniqueId =
            uint256(
                keccak256(
                    abi.encodePacked(string(abi.encodePacked(beneficiary)), block.number, now)
                )
            );
        return uniqueId;
    }

    function _getUnreleasedAmount(uint256 uniqueId) private view returns (uint256) {
        VestingPlan memory plan = _vestingPlans[uniqueId];
        uint256 unreleasedAmount = plan.totalAmount - _released[uniqueId];
        return unreleasedAmount;
    }

    function _calculateWithdrawableAmount(VestingPlan memory plan) private view returns (uint256) {
        //revoked vesting plan
        if (plan.isRevoked) {
            return uint256(0);
        }

        uint256 currentTime = (plan.vestingType == VestingType.TIME ? now : block.number);

        if (currentTime < plan.startTime) {
            return uint256(0);
        }

        //during cliff
        uint256 releasedAmount = _released[plan.uniqueId];
        if (currentTime <= plan.startTime.add(plan.cliffDuration)) {
            if (plan.initialAmount > releasedAmount) {
                return plan.initialAmount.sub(releasedAmount);
            } else {
                return uint256(0);
            }
            //vesting finished
        } else if (currentTime > plan.startTime.add(plan.cliffDuration).add(plan.duration)) {
            if (plan.totalAmount > releasedAmount) {
                return plan.totalAmount.sub(releasedAmount);
            } else {
                return uint256(0);
            }
            // during the vesting duration, exclude cliff
        } else {
            uint256 accumulatstartTime =
                (plan.accumulateDuringCliff ? plan.startTime : plan.startTime + plan.cliffDuration);
            uint256 totalDuration =
                (plan.accumulateDuringCliff ? plan.duration.add(plan.cliffDuration) : plan.duration);

            uint256 intervalCounts;
            if (plan.vestingType == VestingType.TIME) {
                intervalCounts = (
                    totalDuration.mod(plan.interval) == 0
                        ? totalDuration.div(plan.interval)
                        : totalDuration.div(plan.interval).add(1)
                );
            } else {
                intervalCounts = totalDuration;
            }

            uint256 planInterval = (plan.vestingType == VestingType.TIME ? plan.interval : 1);

            uint256 accumulatedAmount =
                plan.totalAmount.sub(plan.initialAmount).mul(currentTime.sub(accumulatstartTime).div(planInterval)).div(
                    intervalCounts
                );

            return accumulatedAmount.add(plan.initialAmount).sub(releasedAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

