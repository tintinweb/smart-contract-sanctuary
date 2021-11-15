// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IStrategy.sol";

contract NativeVault is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // The percentage of funds which should stay in the vault as a buffer for withdrawals
    uint256 public buffer;
    // An array of the strategies used for this vault
    address[] public strategies;
    // A mapping which contains the ratio allocated to strategies
    mapping(address => uint8) public ratios;
    // The total ratio allocated to strategies. Must be below (100 - buffer)
    uint256 public ratioTotal;
    // The wallets allowed to deposit withdraw
    mapping(address => bool) private team;

    // Bytes size of an order
    uint8 constant SINGLE_ORDER_LENGTH = 32;
    // Bytes size of an address
    uint8 constant ADDRESS_SIZE = 20;
    // Orders instruction list
    enum Instructions{ UNUSED, DEPOSIT, WITHDRAW }
    // Bytes size of a ratio
    uint8 constant SINGLE_RATIO_LENGTH = 21;

    // An event triggered when a deposit is completed
    event Fund(uint256 _value);
    // An event triggered when a withdrawal is completed
    event Withdrawal(address indexed _to, uint256 _value);
    // An event triggered when rebalancing orders are set
    event Rebalance(uint8 instruction, address strategy, uint256 amount);

    modifier onlyTeam {
        require(team[msg.sender] == true, "You are not allowed");
        _;
    }

    constructor(string memory _name,
                string memory _symbol,
                uint256 _buffer) ERC20(_name, _symbol) {
        buffer = _buffer;

        // Add team addresses
        team[0xAfCb545E3F2fA80f1AF9F29262b0bD823CD660D5] = true;
        team[0x0C0BB3535E96b47C0E7A65bEFd1A11B7e13BCBeb] = true;
        team[0xBabca9AFd7aD81f2ED9CD6f3A385fC6A133EaA11] = true;
        team[0x27aC4a127ABc567f2Be03a686fD80aB2a9559304] = true;
        team[0xEA29fa603cd0DEdDb183a5Db54FA182b564E8412] = true;
        team[0x90Cc775BB8f21eF9cbA7868c6Aa7e91a13A8a7B8] = true;
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the vault and the different strategies.
    **/
    function overallBalance() public returns (uint) {
        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalBalance += IStrategy(strategies[i]).getVirtualBalance();
        }
        return totalBalance;
    }

    /**
     * @dev Deposits an amount in the vault.
    **/
    function fund() public payable onlyTeam {
        // Check amount is > 0
        require(msg.value > 0);

        uint256 _amount = msg.value;
        uint256 _pool = overallBalance() - _amount;

        // Mint shares
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply()) / _pool;
        }

        emit Fund(msg.value);

        _mint(msg.sender, shares);
    }

    /**
     * @dev Withdraws an amount to the token holder
     * It will check if the buffer has enough balance to perform the transaction
     * If not, we take the largest pool and withdraw the rest of the amount there
    **/
    function withdraw(uint256 _shares) public onlyTeam {

        require(_shares <= balanceOf(msg.sender), "You can't withdraw more shares than you have");

        uint256 sharesValue = overallBalance() * _shares / totalSupply();
        uint256 totalAmount = 0;

        _burn(msg.sender, _shares);

        // Look for most over target strategy
        address strategyToWithdraw;
        uint256 strategyAvailableAmount;
        (strategyToWithdraw, strategyAvailableAmount) = findMostOverTargetStrategy(sharesValue);

        if (sharesValue > strategyAvailableAmount) {
            // Over target strategy is too small, we withdraw from the biggest pool
            (strategyToWithdraw, strategyAvailableAmount) = findMostLockedStrategy();
            require(sharesValue <= strategyAvailableAmount, "Withdrawal amount too big");
        }

        require(sharesValue <= strategyAvailableAmount, "Withdrawal amount is bigger than pool size");

        // Compute pool LP amount to withdraw
        uint256 poolLpAmount = IStrategy(strategyToWithdraw).getConvexLpBalance();
        uint256 poolBalance = IStrategy(strategyToWithdraw).getVirtualBalance();
        uint256 poolLpAmountToWithdraw = (poolLpAmount * sharesValue) / poolBalance;
        totalAmount = IStrategy(strategyToWithdraw).withdraw(poolLpAmountToWithdraw);

        (bool success, ) = payable(msg.sender).call{value : totalAmount}("");
        require(success, "Transfer failed.");

        emit Withdrawal(msg.sender, totalAmount);
    }

    /*
     * @dev This method allows to update the ratios which represents the target allocation for the strategies
     * @param ratios: Any amount of 21-byte orders with the format [20 bytes `address`, 1 byte `ratio` (0-100)]
     */
    function setRatios(bytes memory ratiosBytes) public onlyOwner {
        require(ratiosBytes.length % SINGLE_RATIO_LENGTH == 0, "Ratios are not in the right format");

        uint8 addedRatios = 0;

        for (uint i = 0; i < ratiosBytes.length / SINGLE_RATIO_LENGTH; i++) {
            // Decode #0-#19: Address
            uint160 addressAsInt;
            uint8 addressByte;
            address addressParsed;

            for (uint j = 0; j < ADDRESS_SIZE; j++) {
                uint256 index = (i * SINGLE_RATIO_LENGTH) + j;
                addressAsInt *= 256;
                addressByte = uint8(ratiosBytes[index]);
                addressAsInt += addressByte;
            }
            addressParsed = address(addressAsInt);

            // Check that address is inside our strategies
            getStrategyIndex(addressParsed);

            // Decode #20: Amount
            uint8 ratio = uint8(ratiosBytes[20]);
            addedRatios += ratio;
            ratios[addressParsed] = ratio;
        }

        ratioTotal = addedRatios;
    }

    /*
     * @dev This method is called by the optimizer to pass orders (deposit/withdraw) that the vault should execute to rebalance the strategies.
     * @param orders: Any amount of 32-byte orders with the format [1 byte `instruction`, 20 bytes `address`, 11 bytes `amount`]
     */
    function setOrders(bytes memory orders) public onlyOwner {
        require(orders.length % SINGLE_ORDER_LENGTH == 0, "Orders are not in the right format");

        for (uint i = 0; i < orders.length / SINGLE_ORDER_LENGTH; i++) {
            // Decode #0: Instruction code
            bytes1 instructionByte = orders[i * SINGLE_ORDER_LENGTH];
            uint8 instruction = uint8(instructionByte);

            // Decode #1-#20: Address
            uint160 addressAsInt;
            uint8 addressByte;
            address addressParsed;

            for (uint j = 1; j < ADDRESS_SIZE + 1; j++) {
                uint256 index = (i * SINGLE_ORDER_LENGTH) + j;
                addressAsInt *= 256;
                addressByte = uint8(orders[index]);
                addressAsInt += addressByte;
            }
            addressParsed = address(addressAsInt);

            // Check that address is inside our strategies
            getStrategyIndex(addressParsed);

            // Decode #21-#31: Amount
            uint256 amount;
            uint8 amountByte;

            for (uint k = ADDRESS_SIZE + 1; k < SINGLE_ORDER_LENGTH; k++) {
                uint256 index = (i * SINGLE_ORDER_LENGTH) + k;
                amount *= 256;
                amountByte = uint8(orders[index]);
                amount += amountByte;
            }

            if (instruction == uint8(Instructions.DEPOSIT)) {
                IStrategy(addressParsed).deposit{value: amount}();
                emit Rebalance(instruction, addressParsed, amount);
            } else if (instruction == uint8(Instructions.WITHDRAW)) {
                // Compute pool LP amount to withdraw
                uint256 poolLpAmount = IStrategy(addressParsed).getConvexLpBalance();
                uint256 poolBalance = IStrategy(addressParsed).getVirtualBalance();
                uint256 poolLpAmountToWithdraw = (poolLpAmount * amount) / poolBalance;
                IStrategy(addressParsed).withdraw(poolLpAmountToWithdraw);
                emit Rebalance(instruction, addressParsed, amount);
            } else {
                revert("Instruction not recognized");
            }
        }
    }

    /**
     * @dev Returns the index of the strategy
    **/
    function getStrategyIndex(address strategy) public view returns (uint8) {
        for (uint8 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategy) return i;
        }
        revert("Invalid strategy address");
    }

    /**
     * @dev Adds a strategy to our list of approved strategies
    **/
    function addStrategy(address strategyAddress) public onlyOwner {
        for (uint8 i = 0; i < strategies.length; i++) {
            require(strategies[i] != strategyAddress, "Strategy already exists");
        }
        strategies.push(strategyAddress);
    }

    /**
     * @dev Removes a strategy from our list of approved strategies
     * Transfers the funds back from the strategy to the vault
    **/
    function removeStrategy(address strategy) public onlyOwner {
        if (IStrategy(strategy).getConvexLpBalance() > 0) {
            IStrategy(strategy).withdrawAll();
        }

        uint8 index = getStrategyIndex(strategy);
        require(index < strategies.length);

        address strategyToRemove = strategies[index];
        for (uint8 i = index + 1; i < strategies.length; i++) {
            strategies[i - 1] = strategies[i];
        }

        strategies[strategies.length - 1] = strategyToRemove;
        strategies.pop();

        // Set ratio of strat to 0
        ratioTotal = ratioTotal - ratios[strategy];
        ratios[strategy] = 0;
    }

    /**
     * @dev Will harvest all strategies.
    **/
    function harvestAll() public {
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).harvest(true);
        }
    }

    /**
     * @dev Sets a new percentage value of funds which should stay in the buffer
    **/
    function setBuffer(uint256 _newBuffer) public onlyOwner {
        buffer = _newBuffer;
    }

    /**
     * @dev This methods find the strategy which is the most above its target.
     * If it has enough balance, it will be used to withdraw from here.
    **/
    function findMostOverTargetStrategy(uint256 withdrawAmount) public returns (address, uint256) {
        uint256 balance = overallBalance() - withdrawAmount;
        address overTargetStrategy = strategies[0];

        uint256 optimal = balance * ratios[strategies[0]] / ratioTotal;
        uint256 current = IStrategy(strategies[0]).getVirtualBalance();

        bool isLessThanOpt = current < optimal;
        uint256 overTargetBalance = isLessThanOpt ? optimal - current : current - optimal;

        for (uint256 i = 0; i < strategies.length; i++) {
            optimal = balance * ratios[strategies[i]] / ratioTotal;
            current = IStrategy(strategies[i]).getVirtualBalance();

            if (isLessThanOpt && current > optimal) {
                isLessThanOpt = false;
                overTargetBalance = current - optimal;
                overTargetStrategy = strategies[i];
            } else if (isLessThanOpt && current < optimal) {
                if (optimal - current < overTargetBalance) {
                    overTargetBalance = optimal - current;
                    overTargetStrategy = strategies[i];
                }
            } else if (!isLessThanOpt && current >= optimal) {
                if (current - optimal > overTargetBalance) {
                    overTargetBalance = current - optimal;
                    overTargetStrategy = strategies[i];
                }
            }
        }

        if (isLessThanOpt) {
            overTargetBalance = 0;
        }

        return (overTargetStrategy, overTargetBalance);
    }

    /**
     * @dev This methods find the strategy which has the highest balance.
    **/
    function findMostLockedStrategy() public returns (address, uint256) {
        uint256 current;
        address lockedMostAddress = strategies[0];
        uint256 lockedBalance = IStrategy(strategies[0]).getVirtualBalance();

        for (uint256 i = 0; i < strategies.length; i++) {
            current = IStrategy(strategies[i]).getVirtualBalance();
            if (current > lockedBalance) {
                lockedBalance = current;
                lockedMostAddress = strategies[i];
            }
        }

        return (lockedMostAddress, lockedBalance);
    }

    receive () external payable {}

    /**
     * @dev Temporary method to set team member
     */
    function setTeamMember(address memberAddress) public onlyOwner {
        team[memberAddress] = true;
    }

    /**
     * @dev Temporary method to remove team member
     */
    function removeTeamMember(address memberAddress) public onlyOwner {
        team[memberAddress] = false;
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IStrategy {
    function deposit() external payable returns (uint256);
    function withdraw(uint256 lpAmount) external returns (uint256);
    function withdrawAll() external returns (uint256);
    function harvest(bool _compoundRewards) external;
    function getVirtualBalance() external returns (uint256);
    function getConvexLpBalance() external view returns (uint256);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

