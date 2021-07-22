/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File contracts/ETBurnPool.sol


pragma solidity >=0.8.6;

/**
 * @title ET Burn Pool Contract
 * @author ETHST-TEAM
 * @notice This contract burn ET
 */
contract ETBurnPool {
    ERC20 public ethContract;
    ERC20 public etContract;

    struct Round {
        bool transferred;
        uint256 ethAmount;
        uint256 etBurnAmount;
        mapping(address => uint256) userBurnET;
    }

    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public burnEpoch;

    uint256 public etBurnTotalAmount;
    uint256 public firstRoundStartTimestamp;
    uint256 public intervalSeconds;
    address public etBurnAddress;

    event TransferETH(uint256 indexed epoch, uint256 ethAmount);
    event TransferET(
        uint256 indexed epoch,
        uint256 ethAmount,
        uint256 etBurnAmount,
        bool indexed transferred
    );
    event BurnET(
        uint256 indexed epoch,
        address indexed sender,
        uint256 etBurnAmount
    );
    event WithdrawETH(address indexed sender, uint256 ethRewardsAmount);

    /**
     * @param ethContractAddr Initialize ETH Contract Address
     * @param etContractAddr Initialize ET Contract Address
     * @param etBurnAddr Initialize ET Burn Address
     * @param _firstRoundStartTimestamp Initialize first round start timestamp, should be at 17:00 on a certain day
     * @param _intervalSeconds Initialize interval seconds, 1 day = 86400 seconds
     */
    constructor(
        address ethContractAddr,
        address etContractAddr,
        address etBurnAddr,
        uint256 _firstRoundStartTimestamp,
        uint256 _intervalSeconds
    ) {
        ethContract = ERC20(ethContractAddr);
        etContract = ERC20(etContractAddr);

        etBurnAddress = etBurnAddr;
        firstRoundStartTimestamp = _firstRoundStartTimestamp;
        intervalSeconds = _intervalSeconds;
    }

    /**
     * @dev Add fake burn data
     */
    function addFakeBurnData(uint256 epoch, uint256 n) external {
        for (uint256 i = epoch; i < n; i++) {
            burnEpoch[msg.sender].push(i);
            Round storage round = rounds[i];
            round.userBurnET[msg.sender] += i * 100;
            round.etBurnAmount += i * 100;
            round.ethAmount += i;
        }
    }

    /**
     * @dev Get current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp >= firstRoundStartTimestamp) {
            return
                (block.timestamp - firstRoundStartTimestamp) /
                intervalSeconds +
                1;
        } else {
            return 0;
        }
    }

    /**
     * @dev Get ETH rewards of a user
     */
    function getETHRewards(address user) public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 ethRewards;
        for (uint256 i = 0; i < burnEpoch[user].length; i++) {
            uint256 epoch = burnEpoch[user][i];
            if (epoch < currentEpoch) {
                Round storage round = rounds[epoch];
                if (round.ethAmount > 0) {
                    ethRewards +=
                        (round.ethAmount * round.userBurnET[user]) /
                        round.etBurnAmount;
                }
            }
        }
        return ethRewards;
    }

    /**
     * @dev Transfer ETH to current round or a future round, should run before 17:00 everyday
     */
    function transferETH(uint256 epoch, uint256 ethAmount) external {
        require(epoch > 0, "The epoch must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(epoch >= currentEpoch, "This round has already ended.");
        ethContract.transferFrom(msg.sender, address(this), ethAmount);
        Round storage round = rounds[epoch];
        round.ethAmount += ethAmount;

        emit TransferETH(epoch, ethAmount);
    }

    /**
     * @dev  Transfer ET to burn address, should run after 17:00 everyday
     */
    function transferET(uint256 epoch) external {
        require(epoch > 0, "The epoch must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(epoch < currentEpoch, "This round has not ended yet.");
        Round storage round = rounds[epoch];
        if (round.transferred == true)
            revert("This round has already been transferred.");
        round.transferred = true;
        if (round.etBurnAmount > 0) {
            etContract.transfer(etBurnAddress, round.etBurnAmount);
            etBurnTotalAmount += round.etBurnAmount;
        }

        emit TransferET(
            epoch,
            round.ethAmount,
            round.etBurnAmount,
            round.transferred
        );
    }

    /**
     * @dev Burn ET to a round
     */
    function burnET(uint256 etBurnAmount) external {
        uint256 currentEpoch = getCurrentEpoch();
        require(currentEpoch > 0, "This activity has not started yet.");
        etContract.transferFrom(msg.sender, address(this), etBurnAmount);
        uint256 burnEpochLength = burnEpoch[msg.sender].length;
        if (burnEpochLength > 0) {
            if (burnEpoch[msg.sender][burnEpochLength - 1] < currentEpoch) {
                burnEpoch[msg.sender].push(currentEpoch);
            }
        } else {
            burnEpoch[msg.sender].push(currentEpoch);
        }
        Round storage round = rounds[currentEpoch];
        round.userBurnET[msg.sender] += etBurnAmount;
        round.etBurnAmount += etBurnAmount;

        emit BurnET(currentEpoch, msg.sender, etBurnAmount);
    }

    /**
     * @dev Withdraw ETH
     */
    function withdrawETH() external {
        uint256 ethRewardsAmount = getETHRewards(msg.sender);
        require(ethRewardsAmount > 0, "You have no ETH to withdraw.");
        uint256 currentEpoch = getCurrentEpoch();
        if (burnEpoch[msg.sender][burnEpoch[msg.sender].length - 1] == currentEpoch) {
            burnEpoch[msg.sender] = [currentEpoch];
        } else {
            delete burnEpoch[msg.sender];
        }
        ethContract.transfer(msg.sender, ethRewardsAmount);

        emit WithdrawETH(msg.sender, ethRewardsAmount);
    }

    /**
     * @dev Get current epoch countdown
     */
    function getCurrentEpochCountdown() external view returns (uint256) {
        if (block.timestamp >= firstRoundStartTimestamp) {
            return
                intervalSeconds -
                ((block.timestamp - firstRoundStartTimestamp) %
                    intervalSeconds);
        } else {
            return 0;
        }
    }

    /**
     * @dev Get ETH balance of this contract
     */
    function getETHBalance() external view returns (uint256) {
        return ethContract.balanceOf(address(this));
    }

    /**
     * @dev Get ET balance of this contract
     */
    function getETBalance() external view returns (uint256) {
        return etContract.balanceOf(address(this));
    }
}