// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SliverMint is ERC20 {
    address private creators;
    address private playToEarn;
    address private minting;
    address private marketing;
    address private liquidity;

    uint256 public totalCreatorsSupply;
    uint256 public totalPlayToEarnSupply;
    uint256 public totalMintingSupply;
    uint256 public totalMarketingSupply;
    uint256 public totalLiquiditySupply;

    uint256 public totalCreatorsDistribution;
    uint256 public totalPlayToEarnDistribution;
    uint256 public totalMintingDistribution;
    uint256 public totalMarketingDistribution;
    uint256 public totalLiquidityDistribution;

    uint256 public mintDate;

    uint256 public lastCreatorsDistribution;
    uint256 public lastPlayToEarnDistribution;
    uint256 public lastMintingDistribution;
    uint256 public lastMarketingDistribution;
    uint256 public lastLiquidityDistribution;

    uint256 private creatorsReleaseInterval;
    uint256 private playToEarnReleaseInterval;
    uint256 private mintingReleaseInterval;
    uint256 private marketingReleaseInterval;
    uint256 private liquidityReleaseInterval;

    uint256 private creatorsReleaseSegments;
    uint256 private playToEarnReleaseSegments;
    uint256 private mintingReleaseSegments;
    uint256 private marketingReleaseSegments;
    uint256 private liquidityReleaseSegments;

    uint256 public creatorsDistributionAmount;
    uint256 public playToEarnDistributionAmount;
    uint256 public mintingDistributionAmount;
    uint256 public marketingDistributionAmount;
    uint256 public liquidityDistributionAmount;

    constructor(
        address _creators,
        address _playToEarn,
        address _minting,
        address _marketing,
        address _liquidity
    ) ERC20("Sliver", "SLVR") {
        mintDate = block.timestamp;

        uint256 DAYS = 60 * 60 * 24;
        uint256 WEEKS = DAYS * 7;
        uint256 MONTHS = DAYS * 30;

        creatorsReleaseInterval = 30 * DAYS;
        creatorsReleaseSegments = 24;

        playToEarnReleaseInterval = 6 * MONTHS;
        playToEarnReleaseSegments = 4;

        mintingReleaseInterval = 3 * MONTHS;
        mintingReleaseSegments = 4;

        marketingReleaseInterval = 30 * DAYS;
        marketingReleaseSegments = 24;

        liquidityReleaseInterval = 0;
        liquidityReleaseSegments = 1;

        creators = _creators;
        playToEarn = _playToEarn;
        minting = _minting;
        marketing = _marketing;
        liquidity = _liquidity;

        uint256 supply = 2170000000 * 10**18; //2,170,000,000 $SLVR

        totalMintingSupply = supply / 10 / 2; // %50 of minting supply to be minted on Ethereum
        // 50% of minting supply will be "burned" right here to compensate for polygon mint
        supply -= supply / 10 / 2; //108,500,000 SLIVER to be minted on polygon

        totalCreatorsSupply = supply / 5;
        totalPlayToEarnSupply = supply / 2;
        totalMarketingSupply = supply / 10;
        totalLiquiditySupply = supply / 10;

        creatorsDistributionAmount =
            totalCreatorsSupply /
            creatorsReleaseSegments;
        playToEarnDistributionAmount =
            totalPlayToEarnSupply /
            playToEarnReleaseSegments;
        mintingDistributionAmount = totalMintingSupply / mintingReleaseSegments;
        marketingDistributionAmount =
            totalMarketingSupply /
            marketingReleaseSegments;
        liquidityDistributionAmount =
            totalLiquiditySupply /
            liquidityReleaseSegments;

        _mint(creators, creatorsDistributionAmount);
        _mint(playToEarn, playToEarnDistributionAmount);
        _mint(minting, mintingDistributionAmount);
        _mint(marketing, marketingDistributionAmount);
        _mint(liquidity, liquidityDistributionAmount);

        totalCreatorsDistribution += creatorsDistributionAmount;
        totalPlayToEarnDistribution += playToEarnDistributionAmount;
        totalMintingDistribution += mintingDistributionAmount;
        totalMarketingDistribution += marketingDistributionAmount;
        totalLiquidityDistribution += liquidityDistributionAmount;

        lastCreatorsDistribution = block.timestamp;
        lastPlayToEarnDistribution = block.timestamp;
        lastMintingDistribution = block.timestamp;
        lastMarketingDistribution = block.timestamp;
        lastLiquidityDistribution = block.timestamp;
    }

    function canDistributeCreatorsTokens()
        public
        view
        returns (bool canDistribute)
    {
        canDistribute = false;
        if (
            block.timestamp >=
            (lastCreatorsDistribution + creatorsReleaseInterval) &&
            totalCreatorsDistribution < totalCreatorsSupply
        ) {
            canDistribute = true;
        }
    }

    function canDistributePlayToEarnTokens()
        public
        view
        returns (bool canDistribute)
    {
        canDistribute = false;
        if (
            block.timestamp >=
            (lastPlayToEarnDistribution + playToEarnReleaseInterval) &&
            totalPlayToEarnDistribution < totalPlayToEarnSupply
        ) {
            canDistribute = true;
        }
    }

    function canDistributeMintingTokens()
        public
        view
        returns (bool canDistribute)
    {
        canDistribute = false;
        if (
            block.timestamp >=
            (lastMintingDistribution + mintingReleaseInterval) &&
            totalMintingDistribution < totalMintingSupply
        ) {
            canDistribute = true;
        }
    }

    function canDistributeMarketingTokens()
        public
        view
        returns (bool canDistribute)
    {
        canDistribute = false;
        if (
            block.timestamp >=
            (lastMarketingDistribution + marketingReleaseInterval) &&
            totalMarketingDistribution < totalMarketingSupply
        ) {
            canDistribute = true;
        }
    }

    function canDistributeLiquidityTokens()
        public
        view
        returns (bool canDistribute)
    {
        canDistribute = false;
        if (
            block.timestamp >=
            (lastLiquidityDistribution + liquidityReleaseInterval) &&
            totalLiquidityDistribution < totalLiquiditySupply
        ) {
            canDistribute = true;
        }
    }

    function distributionsAvailable() public view returns (bool available) {
        available = false;
        if (
            canDistributeCreatorsTokens() ||
            canDistributePlayToEarnTokens() ||
            canDistributeMintingTokens() ||
            canDistributeMarketingTokens() ||
            canDistributeLiquidityTokens()
        ) {
            available = true;
        }
    }

    function distributeAllTokens() public {
        require(
            distributionsAvailable(),
            "All current distributions have been made"
        );
        distributeCreatorsTokens();
        distributePlayToEarnTokens();
        distributeMintingTokens();
        distributeMarketingTokens();
        distributeLiquidityTokens();
    }

    function distributeCreatorsTokens() public {
        if (canDistributeCreatorsTokens()) {
            uint256 distributionQty = creatorsDistributionAmount;
            // Subtraction okay, canDistributeCreatorsTokens only returns true if supply > distribution
            uint256 remainingSupply = totalCreatorsSupply -
                totalCreatorsDistribution;
            if (remainingSupply < creatorsDistributionAmount) {
                //distribute the remaining amount
                distributionQty = remainingSupply;
            }
            _mint(creators, distributionQty);
            totalCreatorsDistribution += distributionQty;
        }
    }

    function distributePlayToEarnTokens() public {
        if (canDistributePlayToEarnTokens()) {
            uint256 distributionQty = playToEarnDistributionAmount;
            uint256 remainingSupply = totalPlayToEarnSupply -
                totalPlayToEarnDistribution;
            if (remainingSupply < playToEarnDistributionAmount) {
                distributionQty = remainingSupply;
            }
            _mint(playToEarn, distributionQty);
            totalPlayToEarnDistribution += distributionQty;
        }
    }

    function distributeMintingTokens() public {
        if (canDistributeMintingTokens()) {
            uint256 distributionQty = mintingDistributionAmount;
            uint256 remainingSupply = totalMintingSupply -
                totalMintingDistribution;
            if (remainingSupply < mintingDistributionAmount) {
                distributionQty = remainingSupply;
            }
            _mint(minting, distributionQty);
            totalMintingDistribution += distributionQty;
        }
    }

    function distributeMarketingTokens() public {
        if (canDistributeMarketingTokens()) {
            uint256 distributionQty = marketingDistributionAmount;
            uint256 remainingSupply = totalMarketingSupply -
                totalMarketingDistribution;
            if (remainingSupply < marketingDistributionAmount) {
                distributionQty = remainingSupply;
            }
            _mint(marketing, distributionQty);
            totalMarketingDistribution += distributionQty;
        }
    }

    function distributeLiquidityTokens() public {
        if (canDistributeLiquidityTokens()) {
            uint256 distributionQty = liquidityDistributionAmount;
            uint256 remainingSupply = totalLiquiditySupply -
                totalLiquidityDistribution;
            if (remainingSupply < liquidityDistributionAmount) {
                distributionQty = remainingSupply;
            }
            _mint(liquidity, distributionQty);
            totalLiquidityDistribution += distributionQty;
        }
    }
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