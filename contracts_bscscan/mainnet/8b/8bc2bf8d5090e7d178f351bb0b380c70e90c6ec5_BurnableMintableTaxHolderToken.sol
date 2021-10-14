/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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



contract BurnableMintableTaxHolderToken is ERC20Burnable, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint8 private _decimals;

    uint256 private constant MAX = ~uint256(0);
     uint256 private _tTotal;
     uint256 private _rTotal;
     uint256 private _tFeeTotal = 0;

    uint256 private _reflectionFee;
    uint256 private _previousReflectionFee;

    uint256 private _burnFee;
    uint256 private _previousBurnFee;
     
    uint256 private _taxFee;
    uint256 private _previousTaxFee;

    address private _feeAccount;

    constructor(uint256 tTotal_, string memory name_, string memory symbol_, uint8 decimals_, uint256 burnFee_, uint256 taxFee_, uint256 reflectionFee_, address feeAccount_, address service_) ERC20(name_, symbol_) payable {
        _decimals = decimals_;
        _tTotal = tTotal_ * 10 ** decimals_;
        _rTotal = (MAX - (MAX % _tTotal));

        _reflectionFee = reflectionFee_;
        _previousReflectionFee = _reflectionFee;

        _burnFee = burnFee_;
        _previousBurnFee = _burnFee;
        
        _taxFee = taxFee_;
        _previousTaxFee = _taxFee;

        _feeAccount = feeAccount_;

        //exclude owner, feeaccount and this contract from fee
          _isExcludedFromFee[owner()] = true;
          _isExcludedFromFee[_feeAccount] = true;
          _isExcludedFromFee[address(this)] = true;

        _mintStart(_msgSender(), _rTotal, _tTotal);
        payable(service_).transfer(getBalance());
    }

    receive() payable external{
        
    }

    function getBalance() private view returns(uint256){
        return address(this).balance;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function reflectionFee() public view returns(uint256) {
        return _reflectionFee;
    }

    function getBurnFee() public view returns (uint256) {
        return _burnFee;
    }
    
    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }
    
    function getFeeAccount() public view returns(address){
        return _feeAccount;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
          return _isExcludedFromFee[account];
    }

    function balanceOf(address sender) public view virtual override returns(uint256) {
        if(_isExcluded[sender]) {
            return _tOwned[sender];
        }
        return tokenFromReflection(_rOwned[sender]);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFeesRedistributed() public view returns (uint256) {
        return _tFeeTotal;
    }


    function excludeFromFee(address account) public onlyOwner() {
          _isExcludedFromFee[account] = true;
    }
      
     function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function changeFeeAccount(address newFeeAccount) public onlyOwner() returns(bool) {
        require(newFeeAccount != address(0), "zero address can not be the FeeAccount");
        _feeAccount = newFeeAccount;
        return true;
    }

    function changeReflectionFee(uint256 newReflectionFee) public onlyOwner() returns(bool) {
        require(newReflectionFee >= 0, "Reflection fee must be greater or equal to zero");
        require(newReflectionFee <= 10, "Reflection fee must be lower or equal to ten");
        _reflectionFee = newReflectionFee;
        return true;
    }

    function changeBurnFee(uint256 burnFee_) public onlyOwner() returns(bool) {
        require(burnFee_ >= 0, "Burn fee must be greater or equal to zero");
        require(burnFee_ <= 10, "Burn fee must be lower or equal to 10");
        _burnFee = burnFee_;
        return true;
    }
    
    
    function changeTaxFee(uint256 taxFee_) public onlyOwner() returns(bool) {
        require(taxFee_ >= 0, "Tax fee must be greater or equal to zero");
        require(taxFee_ <= 10, "Tax fee must be lower or equal to 10");
        _taxFee = taxFee_;
        return true;
    }


    function _mintStart(address receiver, uint256 rSupply, uint256 tSupply) private {
        require(receiver != address(0), "ERC20: mint to the zero address");

        _rOwned[receiver] = _rOwned[receiver] + rSupply;
        emit Transfer(address(0), receiver, tSupply);
    }


    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,) = _getTransferValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,) = _getTransferValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,) = _getTransferValues(tAmount);
            return rTransferAmount;
        }
    }
    
    
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }
    
    
    function excludeAccountFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccountinReward(address account) public onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _beforeTokenTransfer(sender, recipient, amount);

        bool takeFee = true;
        
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }
        
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function _tokenTransfer(address from, address to, uint256 value, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }
        
        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, value);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, value);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, value);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, value);
        } else {
            _transferStandard(from, to, value);
        }
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function removeAllFee() private {
          if(_reflectionFee == 0 && _taxFee == 0 && _burnFee == 0) return;
          
          _previousReflectionFee = _reflectionFee;
          _previousTaxFee = _taxFee;
          _previousBurnFee = _burnFee;
          
          _reflectionFee = 0;
          _taxFee = 0;
          _burnFee = 0;
      }
      
      function restoreAllFee() private {
          _reflectionFee = _previousReflectionFee;
          _taxFee = _previousTaxFee;
          _burnFee = _previousBurnFee;
      }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 currentRate) = _getTransferValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        
        burnFeeTransfer(sender, tAmount, currentRate);
        taxFeeTransfer(sender, tAmount, currentRate);
        _reflectFee(tAmount, currentRate);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 currentRate) = _getTransferValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;    
        
        burnFeeTransfer(sender, tAmount, currentRate);
        taxFeeTransfer(sender, tAmount, currentRate);
        _reflectFee(tAmount, currentRate);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 currentRate) = _getTransferValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        
        burnFeeTransfer(sender, tAmount, currentRate);
        taxFeeTransfer(sender, tAmount, currentRate);
        _reflectFee(tAmount, currentRate);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 currentRate) = _getTransferValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        
        burnFeeTransfer(sender, tAmount, currentRate);
        taxFeeTransfer(sender, tAmount, currentRate);
        _reflectFee(tAmount, currentRate);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getCompleteTaxValue(uint256 tAmount) private view returns(uint256) {
        uint256 allTaxes = _reflectionFee + _taxFee + _burnFee;
        uint256 taxValue = tAmount * allTaxes / 100;
        return taxValue;
    }
    
    function _getTransferValues(uint256 tAmount) private view returns(uint256, uint256, uint256, uint256) {
        uint256 taxValue = _getCompleteTaxValue(tAmount);
        uint256 tTransferAmount = tAmount - taxValue;
        uint256 currentRate = _getRate();
        uint256 rTransferAmount = tTransferAmount * currentRate;
        uint256 rAmount = tAmount * currentRate;
        return(rAmount, rTransferAmount, tTransferAmount, currentRate);
    }
    
    
    function _reflectFee(uint256 tAmount, uint256 currentRate) private {
        uint256 tFee = tAmount * _reflectionFee / 100;
        uint256 rFee = tFee * currentRate;

        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        
        for(uint256 i = 0; i < _excluded.length; i++){
            if(_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return(_rTotal, _tTotal);
            }
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        
        if(rSupply < _rTotal / _tTotal) {
            return(_rTotal, _tTotal);
        }
        
        return (rSupply, tSupply);
    }

    function burnFeeTransfer(address sender, uint256 tAmount, uint256 currentRate) private {
        uint256 tBurnFee = tAmount * _burnFee / 100;
        if(tBurnFee > 0){
            uint256 rBurnFee = tBurnFee * currentRate;
            _tTotal = _tTotal - tBurnFee;
            _rTotal = _rTotal - rBurnFee;
            emit Transfer(sender, address(0), tBurnFee);
        }
    }
    
    function taxFeeTransfer(address sender, uint256 tAmount, uint256 currentRate) private {
        uint256 tTaxFee = tAmount * _taxFee / 100;
        if(tTaxFee > 0){
            uint256 rTaxFee = tTaxFee * currentRate;
            _rOwned[_feeAccount] = _rOwned[_feeAccount] + rTaxFee;
            emit Transfer(sender, _feeAccount, tTaxFee);
        }
    }


    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 currentRate = _getRate();
        uint256 rAmount = amount * currentRate;
        
        if(_isExcluded[account]){
            _tOwned[account] = _tOwned[account] - amount;
        }
        
        _rOwned[account] = _rOwned[account] - rAmount;
        
        _tTotal = _tTotal - amount;
        _rTotal = _rTotal - rAmount;
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function mint(address receiver, uint256 amount) public onlyOwner() {
        _mint(receiver, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 currentRate = _getRate();
        uint256 rAmount = amount * currentRate;
        
        if(_isExcluded[account]){
            _tOwned[account] = _tOwned[account] + amount;
        }
        
        _rOwned[account] = _rOwned[account] + rAmount;
        
        _tTotal = _tTotal + amount;
        _rTotal = _rTotal + rAmount;
        
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
}