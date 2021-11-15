// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./RebalancingStrategy1.sol";

/**
 * This contract is part of Orbs Liquidity Nexus protocol. It is a thin wrapper over
 * Sushi LP token and represents liquidity added to the Sushi ETH/USDC pair.
 *
 * The purpose of Liquidity Nexus is to allow single-sided ETH-only farming on SushiSwap.
 * In regular Sushi LP, users add liquidity of both USDC and ETH in equal values. Nexus
 * LP allows users to add liquidity in ETH only, without needing any USDC.
 *
 * So where does the USDC come from? USDC is sourced separately from Orbs Liquidity
 * Nexus and originates from CeFi. This large pool of USDC is deployed in advance and is
 * waiting in the contract until ETH is added. Once ETH is added by users, it is paired
 * with part of the available USDC to generate regular Sushi LP. When liquidity is
 * removed by a user, the Sushi LP is burned, the USDC is returned to the pool and the
 * ETH is returned to the user.
 */
contract NexusLPSushi is ERC20("Nexus LP SushiSwap ETH/USDC", "NSLP"), RebalancingStrategy1 {
    using SafeERC20 for IERC20;

    event Mint(address indexed sender, address indexed beneficiary, uint256 shares);
    event Burn(address indexed sender, address indexed beneficiary, uint256 shares);
    event Pair(
        address indexed sender,
        address indexed minter,
        uint256 pairedUSDC,
        uint256 pairedETH,
        uint256 liquidity
    );
    event Unpair(address indexed sender, address indexed minter, uint256 exitUSDC, uint256 exitETH, uint256 liquidity);
    event ClaimRewards(address indexed sender, uint256 amount);
    event CompoundProfits(address indexed sender, uint256 liquidity);

    /**
     * Stores the original minter for every Nexus LP token, only this original minter
     * can burn the tokens and remove liquidity. This means the address that calls addLiquidity
     * must also call removeLiquidity.
     */
    struct Minter {
        uint256 pairedETH;
        uint256 pairedUSDC;
        uint256 pairedShares; // Nexus LP tokens that represent ETH paired with USDC to create Sushi LP
        uint256 unpairedETH;
        uint256 unpairedShares; // Nexus LP tokens that represent standalone ETH (waiting in this contract's balance)
    }

    uint256 public totalLiquidity;
    uint256 public totalPairedUSDC;
    uint256 public totalPairedETH;
    uint256 public totalPairedShares;
    mapping(address => Minter) public minters;

    /**
     * The contract holds available USDC to be paired with newly deposited ETH to create
     * Sushi LP. If there's not enough available USDC, the ETH deposit tx will revert.
     * This view function shows what's the maximum amount of ETH that can be deposited.
     * Should be called by clients to make sure users' txs are not reverted.
     */
    function availableSpaceToDepositETH() external view returns (uint256 amountETH) {
        return quoteInverse(IERC20(USDC).balanceOf(address(this)));
    }

    /**
     * The number of Sushi LP per Nexus LP share is growing due to rewards compounding.
     * This view function shows this number that should be above 1 at all times.
     */
    function pricePerFullShare() external view returns (uint256) {
        if (totalPairedShares == 0) return 0;
        return (1 ether * totalLiquidity) / totalPairedShares;
    }

    /**
     * Depositors only deposit ETH. This convenience function allows to deposit ETH directly.
     */
    function addLiquidityETH(address beneficiary, uint256 deadline)
        external
        payable
        nonReentrant
        whenNotPaused
        verifyPrice(quote(1 ether))
    {
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        _deposit(beneficiary, amountETH, deadline);
    }

    /**
     * Depositors only deposit ETH. This convenience function allows to deposit WETH (ERC20).
     */
    function addLiquidity(
        address beneficiary,
        uint256 amountETH,
        uint256 deadline
    ) external nonReentrant whenNotPaused verifyPrice(quote(1 ether)) {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountETH);
        _deposit(beneficiary, amountETH, deadline);
    }

    /**
     * When a depositor removes liquidity, they get ETH back. This works with ETH directly.
     * Argument shares is the number of Nexus LP tokens to burn.
     * Note: only the original address that called addLiquidity can call removeLiquidity.
     */
    function removeLiquidityETH(
        address payable beneficiary,
        uint256 shares,
        uint256 deadline
    ) external nonReentrant verifyPrice(quote(1 ether)) returns (uint256 exitETH) {
        exitETH = _withdraw(msg.sender, beneficiary, shares, deadline);
        IWETH(WETH).withdraw(exitETH);
        Address.sendValue(beneficiary, exitETH);
    }

    /**
     * When a depositor removes liquidity, they get ETH back. This works with WETH (ERC20).
     * Argument shares is the number of Nexus LP tokens to burn.
     * Note: only the original address that called addLiquidity can call removeLiquidity.
     */
    function removeLiquidity(
        address beneficiary,
        uint256 shares,
        uint256 deadline
    ) external nonReentrant verifyPrice(quote(1 ether)) returns (uint256 exitETH) {
        exitETH = _withdraw(msg.sender, beneficiary, shares, deadline);
        IERC20(WETH).safeTransfer(beneficiary, exitETH);
    }

    /**
     * Remove the entire Nexus LP balance.
     */
    function removeAllLiquidityETH(address payable beneficiary, uint256 deadline)
        external
        nonReentrant
        verifyPrice(quote(1 ether))
        returns (uint256 exitETH)
    {
        exitETH = _withdraw(msg.sender, beneficiary, balanceOf(msg.sender), deadline);
        require(exitETH <= IERC20(WETH).balanceOf(address(this)), "not enough ETH");
        IWETH(WETH).withdraw(exitETH);
        Address.sendValue(beneficiary, exitETH);
    }

    /**
     * Remove the entire Nexus LP balance.
     */
    function removeAllLiquidity(address beneficiary, uint256 deadline)
        external
        nonReentrant
        verifyPrice(quote(1 ether))
        returns (uint256 exitETH)
    {
        exitETH = _withdraw(msg.sender, beneficiary, balanceOf(msg.sender), deadline);
        IERC20(WETH).safeTransfer(beneficiary, exitETH);
    }

    /**
     * Since all Sushi LP held by this contract are auto deposited in Sushi MasterChef, SUSHI rewards accrue.
     * This allows the governance (the vault working with this contract) to claim the rewards so they can
     * be sold by governance and compounded back inside via compoundProfits.
     */
    function claimRewards() external nonReentrant onlyGovernance {
        _claimRewards();
        uint256 amount = IERC20(REWARD).balanceOf(address(this));
        IERC20(REWARD).safeTransfer(msg.sender, amount);

        emit ClaimRewards(msg.sender, amount);
    }

    /**
     * SUSHI rewards that were claimed by governance (the vault working with this contract) and sold by
     * governance can be compounded back inside via this function. Receives all sold rewards as ETH.
     * Argument capitalProviderRewardPercentmil is the split of the profits that should be given to the
     * provider of USDC. Use 50000 to have an even 50/50 split of the reward profits. Use 20000 to take 80%
     * to the ETH providers and leave 20% of reward profits to the USDC provider.
     */
    function compoundProfits(uint256 amountETH, uint256 capitalProviderRewardPercentmil)
        external
        nonReentrant
        onlyGovernance
        returns (
            uint256 pairedUSDC,
            uint256 pairedETH,
            uint256 liquidity
        )
    {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountETH);

        if (capitalProviderRewardPercentmil > 0) {
            uint256 ownerETH = (amountETH * capitalProviderRewardPercentmil) / 100_000;
            _swapExactETHForUSDC(ownerETH);
            amountETH -= ownerETH;
        }

        amountETH /= 2;
        _swapExactETHForUSDC(amountETH);

        (pairedUSDC, pairedETH, liquidity) = _addLiquidityAndStake(amountETH, block.timestamp); // solhint-disable-line not-rely-on-time
        totalPairedUSDC += pairedUSDC;
        totalPairedETH += pairedETH;
        totalLiquidity += liquidity;
        // not adding to shares to distribute rewards to all shareholders

        emit CompoundProfits(msg.sender, liquidity);
    }

    function _deposit(
        address beneficiary,
        uint256 amountETH,
        uint256 deadline
    ) private {
        uint256 shares = _pair(beneficiary, amountETH, deadline);
        _mint(beneficiary, shares);
        emit Mint(msg.sender, beneficiary, shares);
    }

    /**
     * Pair deposited ETH with USDC available in the contract's balance to create Sushi LP.
     */
    function _pair(
        address minterAddress,
        uint256 amountETH,
        uint256 deadline
    ) private returns (uint256 shares) {
        (uint256 pairedUSDC, uint256 pairedETH, uint256 liquidity) = _addLiquidityAndStake(amountETH, deadline);

        if (totalPairedShares == 0) {
            shares = liquidity;
        } else {
            shares = (liquidity * totalPairedShares) / totalLiquidity;
        }

        Minter storage minter = minters[minterAddress];
        minter.pairedUSDC += pairedUSDC;
        minter.pairedETH += pairedETH;
        minter.pairedShares += shares;

        totalPairedUSDC += pairedUSDC;
        totalPairedETH += pairedETH;
        totalPairedShares += shares;
        totalLiquidity += liquidity;

        emit Pair(msg.sender, minterAddress, pairedUSDC, pairedETH, liquidity);
    }

    function _withdraw(
        address sender,
        address beneficiary,
        uint256 shares,
        uint256 deadline
    ) private returns (uint256 exitETH) {
        Minter storage minter = minters[sender];
        shares = Math.min(shares, minter.pairedShares + minter.unpairedShares);
        require(shares > 0, "sender not in minters");

        if (shares > minter.unpairedShares) {
            _unpair(sender, shares - minter.unpairedShares, deadline);
        }

        exitETH = (shares * minter.unpairedETH) / minter.unpairedShares;
        minter.unpairedETH -= exitETH;
        minter.unpairedShares -= shares;

        _burn(sender, shares);
        emit Burn(sender, beneficiary, shares);
    }

    /**
     * Unpair ETH from USDC by burning Sushi LP and rebalancing IL between the two.
     */
    function _unpair(
        address minterAddress,
        uint256 shares,
        uint256 deadline
    ) private {
        uint256 liquidity = (shares * totalLiquidity) / totalPairedShares;
        (uint256 removedETH, uint256 removedUSDC) = _unstakeAndRemoveLiquidity(liquidity, deadline);

        Minter storage minter = minters[minterAddress];
        uint256 pairedUSDC = (minter.pairedUSDC * shares) / minter.pairedShares;
        uint256 pairedETH = (minter.pairedETH * shares) / minter.pairedShares;
        (uint256 exitUSDC, uint256 exitETH) = applyRebalance(removedUSDC, removedETH, pairedUSDC, pairedETH);

        minter.pairedUSDC -= pairedUSDC;
        minter.pairedETH -= pairedETH;
        minter.pairedShares -= shares;

        minter.unpairedETH += exitETH;
        minter.unpairedShares += shares;

        totalPairedUSDC -= pairedUSDC;
        totalPairedETH -= pairedETH;
        totalPairedShares -= shares;
        totalLiquidity -= liquidity;

        emit Unpair(msg.sender, minterAddress, exitUSDC, exitETH, liquidity);
    }

    /**
     * Allows the owner (the capital provider of USDC) to emergency exit all of their USDC.
     * When called, all Sushi LP is burned to extract ETH+USDC, the USDC part is returned to owner.
     * The ETH will wait in the contract until the original ETH depositors will remove it.
     */
    function emergencyExit(address[] memory minterAddresses) external onlyOwner {
        for (uint256 i = 0; i < minterAddresses.length; i++) {
            address minterAddress = minterAddresses[i];
            Minter storage minter = minters[minterAddress];
            uint256 shares = minter.pairedShares;
            if (shares > 0) {
                _unpair(minterAddress, shares, block.timestamp); //solhint-disable-line not-rely-on-time
            }
        }

        withdrawFreeCapital();
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity 0.8.4;

import "./base/SushiswapIntegration.sol";

abstract contract RebalancingStrategy1 is SushiswapIntegration {
    /**
     * Rebalance usd and eth such that the eth provider takes all IL risk but receives all excess eth,
     * while usd provider's principal is protected
     */
    function applyRebalance(
        uint256 removedUSDC,
        uint256 removedETH,
        uint256 entryUSDC,
        uint256 //entryETH
    ) internal returns (uint256 exitUSDC, uint256 exitETH) {
        if (removedUSDC > entryUSDC) {
            uint256 deltaUSDC = removedUSDC - entryUSDC;
            exitETH = removedETH + _swapExactUSDCForETH(deltaUSDC);
            exitUSDC = entryUSDC;
        } else {
            uint256 deltaUSDC = entryUSDC - removedUSDC;
            uint256 deltaETH = Math.min(removedETH, amountInETHForRequestedOutUSDC(deltaUSDC));
            exitUSDC = removedUSDC + _swapExactETHForUSDC(deltaETH);
            exitETH = removedETH - deltaETH;
        }
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
pragma solidity 0.8.4;

import "./LiquidityNexusBase.sol";
import "../interface/ISushiswapRouter.sol";
import "../interface/ISushiMasterChef.sol";

abstract contract SushiswapIntegration is Salvageable, LiquidityNexusBase {
    using SafeERC20 for IERC20;

    address public constant SLP = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0); // Sushiswap USDC/ETH pair
    address public constant ROUTER = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushiswap Router2
    address public constant MASTERCHEF = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public constant REWARD = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    uint256 public constant POOL_ID = 1;
    address[] public pathToETH = new address[](2);
    address[] public pathToUSDC = new address[](2);

    constructor() {
        pathToUSDC[0] = WETH;
        pathToUSDC[1] = USDC;
        pathToETH[0] = USDC;
        pathToETH[1] = WETH;

        IERC20(USDC).safeApprove(ROUTER, type(uint256).max);
        IERC20(WETH).safeApprove(ROUTER, type(uint256).max);
        IERC20(SLP).safeApprove(ROUTER, type(uint256).max);

        IERC20(SLP).safeApprove(MASTERCHEF, type(uint256).max);
    }

    /**
     * returns price of ETH in USDC
     */
    function quote(uint256 inETH) public view returns (uint256 outUSDC) {
        (uint112 rUSDC, uint112 rETH, ) = IUniswapV2Pair(SLP).getReserves();
        outUSDC = IUniswapV2Router02(ROUTER).quote(inETH, rETH, rUSDC);
    }

    /**
     * returns price of USDC in ETH
     */
    function quoteInverse(uint256 inUSDC) public view returns (uint256 outETH) {
        (uint112 rUSDC, uint112 rETH, ) = IUniswapV2Pair(SLP).getReserves();
        outETH = IUniswapV2Router02(ROUTER).quote(inUSDC, rUSDC, rETH);
    }

    /**
     * returns ETH amount (in) needed when swapping for requested USDC amount (out)
     */
    function amountInETHForRequestedOutUSDC(uint256 outUSDC) public view returns (uint256 inETH) {
        inETH = IUniswapV2Router02(ROUTER).getAmountsIn(outUSDC, pathToUSDC)[0];
    }

    function _swapExactUSDCForETH(uint256 inUSDC) internal returns (uint256 outETH) {
        if (inUSDC == 0) return 0;

        uint256[] memory amounts =
            IUniswapV2Router02(ROUTER).swapExactTokensForTokens(inUSDC, 0, pathToETH, address(this), block.timestamp); // solhint-disable-line not-rely-on-time
        require(inUSDC == amounts[0], "leftover USDC");
        outETH = amounts[1];
    }

    function _swapExactETHForUSDC(uint256 inETH) internal returns (uint256 outUSDC) {
        if (inETH == 0) return 0;

        uint256[] memory amounts =
            IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
                inETH,
                0,
                pathToUSDC,
                address(this),
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        require(inETH == amounts[0], "leftover ETH");
        outUSDC = amounts[1];
    }

    function _addLiquidityAndStake(uint256 amountETH, uint256 deadline)
        internal
        returns (
            uint256 addedUSDC,
            uint256 addedETH,
            uint256 liquidity
        )
    {
        require(IERC20(WETH).balanceOf(address(this)) >= amountETH, "not enough WETH");
        uint256 quotedUSDC = quote(amountETH);
        require(IERC20(USDC).balanceOf(address(this)) >= quotedUSDC, "not enough free capital");

        (addedETH, addedUSDC, liquidity) = IUniswapV2Router02(ROUTER).addLiquidity(
            WETH,
            USDC,
            amountETH,
            quotedUSDC,
            amountETH,
            0,
            address(this),
            deadline
        );
        require(addedETH == amountETH, "leftover ETH");

        IMasterChef(MASTERCHEF).deposit(POOL_ID, liquidity);
    }

    function _unstakeAndRemoveLiquidity(uint256 liquidity, uint256 deadline)
        internal
        returns (uint256 removedETH, uint256 removedUSDC)
    {
        if (liquidity == 0) return (0, 0);

        IMasterChef(MASTERCHEF).withdraw(POOL_ID, liquidity);

        (removedETH, removedUSDC) = IUniswapV2Router02(ROUTER).removeLiquidity(
            WETH,
            USDC,
            liquidity,
            0,
            0,
            address(this),
            deadline
        );
    }

    function _claimRewards() internal {
        IMasterChef(MASTERCHEF).deposit(POOL_ID, 0);
    }

    function canSalvage(address token) public pure override returns (bool) {
        return token != WETH && token != USDC && token != SLP && token != REWARD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./Salvageable.sol";
import "./PriceGuard.sol";

abstract contract LiquidityNexusBase is Ownable, Pausable, Governable, Salvageable, ReentrancyGuard, PriceGuard {
    using SafeERC20 for IERC20;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /**
     * Only the owner is supposed to deposit USDC into this contract.
     */
    function depositCapital(uint256 amount) public onlyOwner {
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
    }

    function depositAllCapital() external onlyOwner {
        depositCapital(IERC20(USDC).balanceOf(msg.sender));
    }

    /**
     * The owner can withdraw the unused USDC capital that they had deposited earlier.
     */
    function withdrawFreeCapital() public onlyOwner {
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        if (balance > 0) {
            IERC20(USDC).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * Pause will only prevent new ETH deposits (addLiquidity). Existing depositors will still
     * be able to removeLiquidity even when paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Owner can disable the PriceGuard oracle in case of emergency
     */
    function pausePriceGuard() external onlyOwner {
        _pausePriceGuard(true);
    }

    function unpausePriceGuard() external onlyOwner {
        _pausePriceGuard(false);
    }

    /**
     * Owner can only salvage unrelated tokens that were sent by mistake.
     */
    function salvage(address[] memory tokens) external onlyOwner {
        _salvage(tokens);
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity 0.8.4;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256,
            uint256,
            uint256
        );

    function massUpdatePools() external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.4;

abstract contract Governable {
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "null governance");
        governance = _governance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Salvageable {
    using SafeERC20 for IERC20;

    function _salvage(address[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(canSalvage(token), "token not salvageable");
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(msg.sender, balance);
            }
        }
    }

    function canSalvage(address token) public pure virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}

abstract contract PriceGuard {
    event PausePriceGuard(address indexed sender, bool paused);

    uint256 public constant SPREAD_TOLERANCE = 10; // max 10% spread
    address public constant CHAINLINK_ORACLE = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool public priceGuardPaused = false;

    modifier verifyPrice(uint256 priceETHUSD) {
        if (!priceGuardPaused) {
            uint256 oraclePrice = chainlinkPriceETHUSD();
            uint256 min = Math.min(priceETHUSD, oraclePrice);
            uint256 max = Math.max(priceETHUSD, oraclePrice);
            uint256 upperLimit = (min * (SPREAD_TOLERANCE + 100)) / 100;
            require(max <= upperLimit, "PriceOracle ETHUSD");
        }
        _;
    }

    /**
     * returns price of ETH in USD (6 decimals)
     */
    function chainlinkPriceETHUSD() public view returns (uint256) {
        return IChainlinkOracle(CHAINLINK_ORACLE).latestAnswer() / 100; // chainlink answer is 8 decimals
    }

    function _pausePriceGuard(bool _paused) internal {
        priceGuardPaused = _paused;
        emit PausePriceGuard(msg.sender, priceGuardPaused);
    }
}

