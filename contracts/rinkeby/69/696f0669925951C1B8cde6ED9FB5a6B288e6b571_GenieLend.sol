// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./amm/VirtualAmm.sol";

contract GenieLend is VirtualAmm, ERC20 {

    /**
    LEND
    Deposit pairedTokens, mint rcTokens ---> add_liquidity to curve pool
    Give user Curve LP tokens (WHAT ABOUT THE IL?)

    BORROW
    Deposit collateral, mint rTokens (rcTokens and rrTokens) using mintRatio. Swap pairedTokens for rcTokens from the curve pool and give that back to the borrower.

    REPAY
    Borrower pays back the pairedTokens with the rrTokens. The pairedTokens are collected in the contract itself (NOT in the curve pool). 

    COLLECT
    Lender gets pro-rata amount of payed back pairedTokens and defaulted collateral tokens. 
    Once the expiry is hit, lender can submit their Curve LP tokens. Contract will call remove_liquidity to get pairedToken and rcToken.

    Now, 
    total amount of paired tokens = payed back (pro_rata) + from curve pool

    And,
    total amount of collateral tokens = defaulted (pro_rata rcToken) collateral
    */

    // ICurve public amm;
    ERC20 public immutable principalToken;
    ERC20 public immutable collateralToken;
    // ERC20 public immutable curvePoolToken;
    uint256 public totalCredit;
    uint256 public collatralizationRatio;
    // bool public poolEmptied;

    mapping (address => uint256) public debt;
    mapping (address => uint256) public repaidDebt;
    mapping (address => uint256) public credit;
    mapping (address => uint256) public collateral;

    constructor(ERC20 _principalToken, ERC20 _collateralToken/* , ERC20 _curvePoolToken */, uint256 _amp, uint256 _collatralizationRatio) ERC20("Bond Token", "BT") VirtualAmm(_amp) {
        principalToken = _principalToken;
        collateralToken = _collateralToken;
        // curvePoolToken = _curvePoolToken;
        collatralizationRatio = _collatralizationRatio;
    }

    // function setAmm(ICurve _amm) external {
    //     amm = _amm;
    // }

    function lend(uint256 principalAmount) external {
        // NOTE: Block any deposits after expiry
        // Deposit pairedTokens, mint rcTokens ---> add_liquidity to curve pool
        // Give user Curve LP tokens (WHAT ABOUT THE IL?)
        require(
            principalToken.transferFrom(msg.sender, address(this), principalAmount),
            "Failed to transfer principal token"
        );

        // principalToken.approve(address(amm), principalAmount);

        // uint256 principalTokenBal = principalToken.balanceOf(address(amm));
        // uint256 bondTokenBal = balanceOf(address(amm));

        if (balances[0] >= balances[1]) {
            // 0% interest for lender
            _mint(address(this), principalAmount);
            // _approve(address(this), address(amm), principalAmount);

            _addLiquidity([principalAmount, principalAmount]);

            credit[msg.sender] += principalAmount;
            totalCredit += principalAmount;
        }
        else {
            // +ve interest for lender
            // uint256 _before = balanceOf(address(this));
            // amm.exchange(0, 1, principalAmount, 0);
            // uint256 _after = balanceOf(address(this));

            uint256 dy = _swap(0, 1, principalAmount);
            credit[msg.sender] += dy;
            totalCredit += dy;
        }
    }

    function borrow(uint256 collateralAmount) external {
        // Deposit collateral, mint rTokens (rcTokens and rrTokens) using mintRatio. 
        // Swap pairedTokens for rcTokens from the curve pool and give that back to the borrower.   

        require(
            collateralToken.transferFrom(msg.sender, address(this), collateralAmount),
            "Failed to transfer collateral token"
        );

        // NOTE: Debt should be the amount of principal tokens the borrower needs to pay back before the expiry
        uint256 bondTokenAmount = getBondAmountFromCollateral(collateralAmount);
        debt[msg.sender] = bondTokenAmount;

        _mint(address(this), bondTokenAmount);
        // _approve(address(this), address(amm), bondTokenAmount);

        // uint256 _before = principalToken.balanceOf(address(this));
        // amm.exchange(1, 0, bondTokenAmount, 0);
        // uint256 _after = principalToken.balanceOf(address(this));

        uint256 dy = _swap(1, 0, bondTokenAmount);
        
        principalToken.transfer(msg.sender, dy);

        collateral[msg.sender] += collateralAmount;
    }

    function repay(uint256 principalAmountRepayed) external {
        // Borrower pays back the pairedTokens with the rrTokens. 
        // The pairedTokens are collected in the contract itself (NOT in the curve pool). 

        // NOTE: Block repays after the expiry date.
        require(
            principalToken.transferFrom(msg.sender, address(this), principalAmountRepayed),
            "Failed to transfer principal token"
        );

        uint256 freedUpCollateral = (principalAmountRepayed*collateral[msg.sender])/debt[msg.sender];

        // debt[msg.sender] = debt[msg.sender] - principalAmountRepayed;
        repaidDebt[msg.sender] += principalAmountRepayed;

        collateralToken.transfer(msg.sender, freedUpCollateral);
    }

    function getFreedUpCollateral(uint256 principalAmountRepayed) external view returns(uint256) {
        return (principalAmountRepayed*collateral[msg.sender])/debt[msg.sender];
    }

    function collect() external {
        // NOTE: Handle collection in case it's called before expiry
        // Lender gets pro-rata amount of payed back pairedTokens and defaulted collateral tokens. 
        // Once the expiry is hit, lender can submit their Curve LP tokens. Contract will call remove_liquidity to get pairedToken and rcToken.   
        if (ammTotalSupply > 0) {
            _removeAllLiquidity();
        }

        uint256 proRataDebt = (credit[msg.sender]*principalToken.balanceOf(address(this)))/totalCredit;
        uint256 proRataCollateral = (credit[msg.sender]*collateralToken.balanceOf(address(this)))/totalCredit;
        principalToken.transfer(msg.sender, proRataDebt);
        collateralToken.transfer(msg.sender, proRataCollateral);

        totalCredit = totalCredit - credit[msg.sender];
        credit[msg.sender] = 0;
    }

    function getBondAmountFromCollateral(uint256 collateralAmount) public view returns(uint256 bondAmount) {
        // NOTE: Use mintRatio to calculate bond token(s) amount
        return collateralAmount/collatralizationRatio;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// NOTE: We just need a record for the LP token, not the whole contract.

contract VirtualAmm {

    uint256 public ammTotalSupply;
    uint256 public initialA;
    uint256 public futureA;
    uint256 public initialATime;
    uint256 public futureATime;
    uint256[2] public balances;

    uint256[2] public RATES = [1, 1];
    uint256 public PRECISION = 10**18;

    constructor(uint256 _amp) {
        initialA = _amp;
        futureA = _amp;
    }

    function _Amp() internal view returns(uint256) {
        // Handle ramping A up or down
        uint256 t1 = futureATime;
        uint256 a1 = futureA;

        if (block.timestamp < t1) {
            uint256 a0 = initialA;
            uint256 t0 = initialATime;  
            // Expressions in uint256 cannot have negative numbers, thus "if"
            if (a1 > a0) {
                return a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0);
            }
            else {
                return a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0);
            }
        }
        else {
            // when t1 == 0 or block.timestamp >= t1
            return a1;
        }
    }

    function _get_D(uint256[2] memory xp, uint256 amp) internal view returns(uint256) {
        uint256 S = 0;
        for (uint256 i = 0; i < 2; i++) {
            S += xp[i];
        }
        if (S == 0) {
            return 0;
        }

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * 2;
        for (uint256 i = 0; i < 255; i++) {
            uint256 D_P = D;
            for (uint256 j = 0; j < 2; j++) {
                // If division by 0, this will be borked: only withdrawal will work. And that is good
                D_P = D_P * D / (xp[j] * 2);
            }
            Dprev = D;
            D = (Ann * S + D_P *2)*D/((Ann - 1) * D + 3*D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1) {
                    break;
                }
            }
            else {
                if (Dprev - D <= 1) {
                    break;
                }
            }
        }

        return D;
    }

    function _xp_mem(uint256[2] memory _balances) internal view returns(uint256[2] memory result) {
        result = RATES;
        for (uint256 i = 0; i < 2; i++) {
            result[i] = result[i] * _balances[i]/PRECISION;
        }
        return result;
    }

    function _getDmem(uint256[2] memory _balances, uint256 _amp) internal view returns(uint256) {
        return _get_D(_xp_mem(_balances), _amp);
    }

    function _addLiquidity(uint256[2] memory amounts) internal {
        uint256 amp = _Amp();

        // Initial invariant
        uint256 d0 = 0;
        uint256[2] memory oldBalances = balances;

        if (ammTotalSupply > 0) {
            d0 = _getDmem(oldBalances, amp);
        }
        uint256[2] memory newBalances = oldBalances;

        for (uint256 i = 0; i < 2; i++) {
            uint256 inAmount = amounts[i];
            if (ammTotalSupply == 0) {
                assert(inAmount > 0); // dev: initial deposit requires all coins
            }
            // address inCoin = coins[i];

            // Take coins from the sender
            newBalances[i] = oldBalances[i] + inAmount;            
        }

        // Invariant after change
        uint256 d1 = _getDmem(newBalances, amp);
        assert(d1 > d0);

        balances = newBalances;

        ammTotalSupply == 0
            ? ammTotalSupply += d1
            : ammTotalSupply += ammTotalSupply * (d1-d0)/d0;
    }

    function _removeAllLiquidity() internal {
        balances = [0, 0];
        ammTotalSupply = 0;
    }

    function _getY(
        uint8 i, 
        uint8 j, 
        uint256 x, 
        uint256[2] memory xp_
    ) internal view returns(uint256) {
        // x in the input is converted to the same price/precision
        
        assert(i != j); // dev: same coin
        assert(j >= 0); // dev: j below zero
        assert(j < 2); // dev: j above 2

        uint256 amp = _Amp();
        uint256 D = _get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * 2;

        uint256 _x = 0;
        for (uint256 _i = 0; _i < 2; _i++) {
            if (_i == i) {
                _x = x;
            }
            else if (_i != j) {
                _x = xp_[_i];
            }
            else {
                continue;
            }
            S_ += _x;
            c = c * D / (_x * 2);
        }
        c = c * D / (Ann * 2);
        uint256 b = S_ + D / Ann;
        uint256 y_prev = 0;
        uint256 y = D;
        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y*y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    break;
                }
            }
            else {
                if (y_prev - y <= 1) {
                    break;
                }
            }
        }
        return y;
    }

    function _swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
        // uint256 minDy
    ) internal returns(uint256 dy) {
        uint256[2] memory rates = RATES;

        uint256[2] memory oldBalances = balances;
        uint256[2] memory xp = _xp_mem(oldBalances);

        uint256 dx_w_fee = dx;

        uint256 x = xp[tokenIndexFrom] + dx_w_fee * rates[tokenIndexFrom] / PRECISION;
        uint256 y = _getY(tokenIndexFrom, tokenIndexTo, x, xp);

        dy = xp[tokenIndexTo] - y - 1;  //-1 just in case there were some rounding errors

        // Convert all to real units
        dy = dy * PRECISION / rates[tokenIndexTo];

        // Change balances exactly in same way as we change actual ERC20 coin amounts
        balances[tokenIndexFrom] = oldBalances[tokenIndexFrom] + dx_w_fee;
        // When rounding errors happen, we undercharge admin fee in favor of LP
        balances[tokenIndexTo] = oldBalances[tokenIndexTo] - dy;
    }

    /* function _swapTest(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
        // uint256 minDy
    ) internal returns(uint256 dy) {
        uint256[2] memory rates = RATES;

        uint256[2] memory oldBalances = balances;
        uint256[2] memory xp = _xp_mem(oldBalances);

        uint256 dx_w_fee = dx;

        uint256 x = xp[tokenIndexFrom] + dx_w_fee * rates[tokenIndexFrom] / PRECISION;
        uint256 y = _getY(tokenIndexFrom, tokenIndexTo, x, xp);

        dy = xp[tokenIndexTo] - y - 1;  //-1 just in case there were some rounding errors

        // Convert all to real units
        dy = dy * PRECISION / rates[tokenIndexTo];

        // Change balances exactly in same way as we change actual ERC20 coin amounts
        balances[tokenIndexFrom] = oldBalances[tokenIndexFrom] + dx_w_fee;
        // When rounding errors happen, we undercharge admin fee in favor of LP
        balances[tokenIndexTo] = oldBalances[tokenIndexTo] - dy;
    } */
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
        return msg.data;
    }
}

