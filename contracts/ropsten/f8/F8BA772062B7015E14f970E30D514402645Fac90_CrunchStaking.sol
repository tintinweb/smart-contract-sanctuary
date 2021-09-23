// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./erc677/IERC677Receiver.sol";
import "./access/HasCrunchParent.sol";
import "./CrunchToken.sol";

/**
 * DataCrunch Staking contract for the CRUNCH token.
 *
 * To start staking, use the {CrunchStaking-deposit(address)} method, but this require an allowance from your account.
 * Another method is to do a {CrunchToken-transferAndCall(address, uint256, bytes)} to avoid doing 2 transactions. (as per ERC-677 standart)
 *
 * Withdrawing will withdraw everything. There is currently no method to only withdraw a specific amount.
 *
 * @author Enzo CACERES
 * @author Arnaud CASTILLO
 */
contract CrunchStaking is HasCrunchParent, IERC677Receiver {
    event Withdrawed(
        address indexed to,
        uint256 reward,
        uint256 staked,
        uint256 totalAmount
    );

    event EmergencyWithdrawed(address indexed to, uint256 staked);
    event Deposited(address indexed sender, uint256 amount);
    event RewardPerDayUpdated(uint256 rewardPerDay, uint256 totalDebt);

    struct Holder {
        /** Index in `addresses`, used for faster lookup in case of a remove. */
        uint256 index;
        /** When does an holder stake for the first time (set to `block.timestamp`). */
        uint256 start;
        /** Total amount staked by the holder. */
        uint256 totalStaked;
        /** When the reward per day is updated, the reward debt is updated to ensure that the previous reward they could have got isn't lost. */
        uint256 rewardDebt;
        /** Individual stakes. */
        Stake[] stakes;
    }

    struct Stake {
        /** How much the stake is. */
        uint256 amount;
        /** When does the stakes 'start' is. When created it is `block.timestamp`, and is updated when the `reward per day` is updated. */
        uint256 start;
    }

    /** The `reward per day` is the amount of tokens rewarded for 1 million CRUNCHs staked over a 1 day period. */
    uint256 public rewardPerDay;

    /** List of all currently staking addresses. Used for looping. */
    address[] public addresses;

    /** address to Holder mapping. */
    mapping(address => Holder) public holders;

    /** Currently total staked amount by everyone. It is incremented when someone deposit token, and decremented when someone withdraw. This value does not include the rewards. */
    uint256 public totalStaked;

    /** @dev Initializes the contract by specifying the parent `crunch` and the initial `rewardPerDay`. */
    constructor(CrunchToken crunch, uint256 _rewardPerDay)
        HasCrunchParent(crunch)
    {
        rewardPerDay = _rewardPerDay;
    }

    /**
     * @dev Deposit an `amount` of tokens from your account to this contract.
     *
     * This will start the staking with the provided amount.
     * The implementation call {IERC20-transferFrom}, so the caller must have previously {IERC20-approve} the `amount`.
     *
     * Emits a {Deposited} event.
     *
     * Requirements:
     * - `amount` cannot be the zero address.
     * - `caller` must have a balance of at least `amount`.
     *
     * @param amount amount to reposit.
     */
    function deposit(uint256 amount) external {
        crunch.transferFrom(_msgSender(), address(this), amount);

        _deposit(_msgSender(), amount);
    }

    /**
     * Withdraw the staked tokens with the reward.
     *
     * Emits a {Withdrawed} event.
     *
     * Requirements:
     * - `caller` to be staking.
     */
    function withdraw() external {
        _withdraw(_msgSender());
    }

    /**
     * Returns the current reserve for rewards.
     *
     * @return the contract balance - the total staked.
     */
    function reserve() public view returns (uint256) {
        uint256 balance = contractBalance();

        if (totalStaked > balance) {
            revert(
                "Staking: the balance has less CRUNCH than the total staked"
            );
        }

        return balance - totalStaked;
    }

    /**
     * Test if the caller is currently staking.
     *
     * @return `true` if the caller is staking, else if not.
     */
    function isCallerStaking() external view returns (bool) {
        return isStaking(_msgSender());
    }

    /**
     * Test if an address is currently staking.
     *
     * @param `addr` address to test.
     * @return `true` if the address is staking, else if not.
     */
    function isStaking(address addr) public view returns (bool) {
        return _isStaking(holders[addr]);
    }

    /**
     * Get the current balance in CRUNCH of this smart contract.
     *
     * @return The current staking contract's balance in CRUNCH.
     */
    function contractBalance() public view returns (uint256) {
        return crunch.balanceOf(address(this));
    }

    /**
     * Returns the sum of the specified `addr` staked amount.
     *
     * @param addr address to check.
     * @return the total staked of the holder.
     */
    function totalStakedOf(address addr) external view returns (uint256) {
        return holders[addr].totalStaked;
    }

    /**
     * Returns the computed reward of everyone.
     *
     * @return total the computed total reward of everyone.
     */
    function totalReward() public view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];

            total += totalRewardOf(addr);
        }
    }

    /**
     * Compute the reward of the specified `addr`.
     *
     * @param addr address to test.
     * @return the reward the address would get.
     */
    function totalRewardOf(address addr) public view returns (uint256) {
        Holder storage holder = holders[addr];

        return _computeRewardOf(holder);
    }

    /**
     * Sum the reward debt of everyone.
     *
     * @return total the sum of all `Holder.rewardDebt`.
     */
    function totalRewardDebt() external view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];

            total += rewardDebtOf(addr);
        }
    }

    /**
     * Get the reward debt of an holder.
     *
     * @param addr holder's address.
     * @return the reward debt of the holder.
     */
    function rewardDebtOf(address addr) public view returns (uint256) {
        return holders[addr].rewardDebt;
    }

    /**
     * Test if the reserve is sufficient to cover the `{totalReward()}`.
     *
     * @return whether the reserve has enough CRUNCH to give to everyone.
     */
    function isReserveSufficient() external view returns (bool) {
        return _isReserveSufficient(totalReward());
    }

    /**
     * Test if the reserve is sufficient to cover the `{totalRewardOf(address)}` of the specified address.
     *
     * @param addr address to test.
     * @return whether the reserve has enough CRUNCH to give to this address.
     */
    function isReserveSufficientFor(address addr) external view returns (bool) {
        return _isReserveSufficient(totalRewardOf(addr));
    }

    /**
     * Get the number of address current staking.
     *
     * @return the length of the `addresses` array.
     */
    function stakerCount() external view returns (uint256) {
        return addresses.length;
    }

    /**
     * Get the stakes array of an holder.
     *
     * @param addr address to get the stakes array.
     * @return the holder's stakes array.
     */
    function stakesOf(address addr) external view returns (Stake[] memory) {
        return holders[addr].stakes;
    }

    /**
     * Get the stakes array length of an holder.
     *
     * @param addr address to get the stakes array length.
     * @return the length of the `stakes` array.
     */
    function stakesCountOf(address addr) external view returns (uint256) {
        return holders[addr].stakes.length;
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Force an address to withdraw.
     *
     * @dev Should only be called if a {CrunchStaking-destroy()} would cost too much gas to be executed.
     *
     * @param addr address to withdraw.
     */
    function forceWithdraw(address addr) external onlyOwner {
        _withdraw(addr);
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Emergency withdraw.
     *
     * All rewards are discarded. Only initial staked amount will be transfered back!
     *
     * Emits a {EmergencyWithdrawed} event.
     *
     * Requirements:
     * - `caller` to be staking.
     */
    function emergencyWithdraw() external {
        _emergencyWithdraw(_msgSender());
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Force an address to emergency withdraw.
     *
     * @dev Should only be called if a {CrunchStaking-emergencyDestroy()} would cost too much gas to be executed.
     *
     * @param addr address to emergency withdraw.
     */
    function forceEmergencyWithdraw(address addr) external onlyOwner {
        _emergencyWithdraw(addr);
    }

    /**
     * Update the reward per day.
     *
     * This will recompute a reward debt with the previous reward per day value.
     * The debt is used to make sure that everyone will keep their rewarded tokens using the previous reward per day value for the calculation.
     *
     * Emits a {RewardPerDayUpdated} event.
     *
     * Requirements:
     * - `to` must not be the same as the reward per day.
     * - `to` must be below or equal to 15000.
     *
     * @param to new reward per day value.
     */
    function setRewardPerDay(uint256 to) external onlyOwner {
        require(
            rewardPerDay != to,
            "Staking: reward per day value must be different"
        );
        require(
            to <= 15000,
            "Staking: reward per day must be below 15000/1M token/day"
        );

        uint256 debt = _updateDebts();
        rewardPerDay = to;

        emit RewardPerDayUpdated(rewardPerDay, debt);
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Empty the reserve if there is a problem.
     */
    function emptyReserve() external onlyOwner {
        uint256 amount = reserve();

        require(amount != 0, "Staking: reserve is empty");

        crunch.transfer(owner(), amount);
    }

    /**
     * Destroy the contact after withdrawing everyone.
     *
     * @dev If the reserve is not zero after the withdraw, the remaining will be sent back to the contract's owner.
     */
    function destroy() external onlyOwner {
        uint256 usable = reserve();

        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            uint256 reward = _computeRewardOf(holder);

            require(usable >= reward, "Staking: reserve does not have enough");

            uint256 total = holder.totalStaked + reward;
            crunch.transfer(addr, total);
        }

        _transferRemainingAndSelfDestruct();
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Destroy the contact after emergency withdrawing everyone, avoiding the reward computation to save gas.
     *
     * If the reserve is not zero after the withdraw, the remaining will be sent back to the contract's owner.
     */
    function emergencyDestroy() external onlyOwner {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            crunch.transfer(addr, holder.totalStaked);
        }

        _transferRemainingAndSelfDestruct();
    }

    /**
     * @dev ONLY FOR CRITICAL EMERGENCY!!
     *
     * Destroy the contact without withdrawing anyone.
     * Only use this function if the code has a fatal bug and its not possible to do otherwise.
     */
    function criticalDestroy() external onlyOwner {
        _transferRemainingAndSelfDestruct();
    }

    /** @dev Internal function called when the {IERC677-transferAndCall} is used. */
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external override onlyCrunchParent {
        data; /* silence unused */

        _deposit(sender, value);
    }

    /**
     * Deposit.
     *
     * @dev If the depositor is not currently holding, the `Holder.start` is set and his address is added to the addresses list.
     *
     * @param from depositor address.
     * @param amount amount to deposit.
     */
    function _deposit(address from, uint256 amount) internal {
        require(amount != 0, "cannot deposit zero");

        Holder storage holder = holders[from];

        if (!_isStaking(holder)) {
            holder.start = block.timestamp;
            holder.index = addresses.length;
            addresses.push(from);
        }

        holder.totalStaked += amount;
        holder.stakes.push(Stake({amount: amount, start: block.timestamp}));

        totalStaked += amount;

        emit Deposited(from, amount);
    }

    /**
     * Withdraw.
     *
     * @dev This will remove the `Holder` from the `holders` mapping and the address from the `addresses` array.
     *
     * Requirements:
     * - `addr` must be staking.
     * - the reserve must have enough token.
     *
     * @param addr address to withdraw.
     */
    function _withdraw(address addr) internal {
        Holder storage holder = holders[addr];

        require(_isStaking(holder), "Staking: no stakes");

        uint256 reward = _computeRewardOf(holder);

        require(
            _isReserveSufficient(reward),
            "Staking: the reserve does not have enough token"
        );

        uint256 staked = holder.totalStaked;
        uint256 total = staked + reward;
        crunch.transfer(addr, total);

        totalStaked -= staked;

        _deleteAddress(holder.index);
        delete holders[addr];

        emit Withdrawed(addr, reward, staked, total);
    }

    /**
     * Emergency withdraw.
     *
     * This is basically the same as {CrunchStaking-_withdraw(address)}, but without the reward.
     * This function must only be used for emergencies as it consume less gas and does not have the check for the reserve.
     *
     * @dev This will remove the `Holder` from the `holders` mapping and the address from the `addresses` array.
     *
     * Requirements:
     * - `addr` must be staking.
     *
     * @param addr address to withdraw.
     */
    function _emergencyWithdraw(address addr) internal {
        Holder storage holder = holders[addr];

        require(_isStaking(holder), "Staking: no stakes");

        uint256 staked = holder.totalStaked;
        crunch.transfer(addr, staked);

        totalStaked -= staked;

        _deleteAddress(holder.index);
        delete holders[addr];

        emit EmergencyWithdrawed(addr, staked);
    }

    /**
     * Test if the `reserve` is sufficiant for a specified reward.
     *
     * @param reward value to test.
     * @return if the reserve is bigger or equal to the `reward` parameter.
     */
    function _isReserveSufficient(uint256 reward) private view returns (bool) {
        return reserve() >= reward;
    }

    /**
     * Test if an holder struct is currently staking.
     *
     * @dev Its done by testing if the stake array length is equal to zero. Since its not possible, it mean that the holder is not currently staking and the struct is only zero.
     *
     * @param holder holder struct.
     * @return `true` if the holder is staking, `false` otherwise.
     */
    function _isStaking(Holder storage holder) internal view returns (bool) {
        return holder.stakes.length != 0;
    }

    /**
     * Update the reward debt of all holders.
     *
     * @dev Usually called before a `reward per day` update.
     *
     * @return total total debt updated.
     */
    function _updateDebts() internal returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            uint256 debt = _updateDebtsOf(holder);

            holder.rewardDebt += debt;

            total += debt;
        }
    }

    /**
     * Update the reward debt of a specified `holder`.
     *
     * @param holder holder struct to update.
     * @return total sum of debt added.
     */
    function _updateDebtsOf(Holder storage holder)
        internal
        returns (uint256 total)
    {
        uint256 length = holder.stakes.length;
        for (uint256 index = 0; index < length; index++) {
            Stake storage stake = holder.stakes[index];

            total += _computeStakeReward(stake);

            stake.start = block.timestamp;
        }
    }

    /**
     * Compute the reward for every holder.
     *
     * @return total the total of all of the reward for all of the holders.
     */
    function _computeTotalReward() internal view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            total += _computeRewardOf(holder);
        }
    }

    /**
     * Compute all stakes reward for an holder.
     *
     * @param holder the holder struct.
     * @return total total reward for the holder (including the debt).
     */
    function _computeRewardOf(Holder storage holder)
        internal
        view
        returns (uint256 total)
    {
        uint256 length = holder.stakes.length;
        for (uint256 index = 0; index < length; index++) {
            Stake storage stake = holder.stakes[index];

            total += _computeStakeReward(stake);
        }

        total += holder.rewardDebt;
    }

    /**
     * Compute the reward of a single stake.
     *
     * @param stake the stake struct.
     * @return the token rewarded (does not include the debt).
     */
    function _computeStakeReward(Stake storage stake)
        internal
        view
        returns (uint256)
    {
        uint256 numberOfDays = ((block.timestamp - stake.start) / 1 days);

        return (stake.amount * numberOfDays * rewardPerDay) / 1_000_000;
    }

    /**
     * Delete an address from the `addresses` array.
     *
     * @dev To avoid holes, the last value will replace the deleted address.
     *
     * @param index address's index to delete.
     */
    function _deleteAddress(uint256 index) internal {
        uint256 length = addresses.length;
        require(
            length != 0,
            "Staking: cannot remove address if array length is zero"
        );

        uint256 last = length - 1;
        if (last != index) {
            address addr = addresses[last];
            addresses[index] = addr;
            holders[addr].index = index;
        }

        addresses.pop();
    }

    /**
     * Transfer the remaining tokens back to the current contract owner and then self destruct.
     *
     * @dev This function must only be called for destruction!!
     * @dev If the balance is 0, the `CrunchToken#transfer(address, uint256)` is not called.
     */
    function _transferRemainingAndSelfDestruct() internal {
        uint256 remaining = contractBalance();
        if (remaining != 0) {
            crunch.transfer(owner(), remaining);
        }

        selfdestruct(payable(owner()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./erc677/ERC677.sol";

contract CrunchToken is ERC677, ERC20Burnable {
    constructor() ERC20("Crunch Token", "CRUNCH") {
        _mint(msg.sender, 10765163 * 10**decimals());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../CrunchToken.sol";

contract HasCrunchParent is Ownable {
    event ParentUpdated(address from, address to);

    CrunchToken public crunch;

    constructor(CrunchToken _crunch) {
        crunch = _crunch;

        emit ParentUpdated(address(0), address(crunch));
    }

    modifier onlyCrunchParent() {
        require(
            address(crunch) == _msgSender(),
            "HasCrunchParent: caller is not the crunch token"
        );
        _;
    }

    function setCrunch(CrunchToken _crunch) public onlyOwner {
        require(address(crunch) != address(_crunch), "useless to update to same crunch token");

        emit ParentUpdated(address(crunch), address(_crunch));

        crunch = _crunch;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC677.sol";
import "./IERC677.sol";
import "./IERC677Receiver.sol";

abstract contract ERC677 is IERC677, ERC20 {
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override returns (bool success) {
        super.transfer(recipient, amount);

        emit TransferAndCall(msg.sender, recipient, amount, data);

        if (isContract(recipient)) {
            IERC677Receiver receiver = IERC677Receiver(recipient);
            receiver.onTokenTransfer(msg.sender, amount, data);
        }

        return true;
    }

    function isContract(address addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(addr)
        }
        return length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677 is IERC20 {
    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @param data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external returns (bool success);

    event TransferAndCall(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}