// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";


contract TestToken is IERC20, IERC20Metadata, Ownable {
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isServiceWallet;

    mapping(address => bool) private _isExcluded;

    mapping(address => uint256[]) private _dailySales;

    uint256 private _startBlock;

    uint256 private _totalSupply;

    uint8 private _decimals = 18;

    address private _burnWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 private MAX_SALE_AMOUNT = 150000000 * 10 ** _decimals;

    uint256 private MAX_START_BUY = 1000000 * 10 ** _decimals;

    uint256[4] public _saleFees = [10,15,20,25];

    uint256 public _userFee = 90;

    uint256 public _buyFee = 10;

    uint256 public _burnFee = 2;

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
    constructor(address cOwner) Ownable(cOwner) {
        _name = "TEST";
        _symbol = "TESTSYMB";
        _totalSupply = 100000000000 * 10 ** _decimals;
        _balances[cOwner] = _totalSupply;
        _isExcluded[cOwner] = true;
        emit Transfer(address(0), cOwner, _totalSupply);

    }


    function startPresale() public onlyOwner {
        require(_startBlock == 0, "Presale was already started");
        _startBlock = block.number;
    }


    function addService(address account) public onlyOwner {
        require(!_isServiceWallet[account], "Wallet is already set as service");
        _isServiceWallet[account] = true;
    }

    function removeService(address account) public onlyOwner {
        require(_isServiceWallet[account], "Wallet is not a service");
        _isServiceWallet[account] = false;
    }


    function includeInFee(address account) public onlyOwner {
        require(_isExcluded[account], "Wallet is already excluded from fee");
        _isExcluded[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        require(!_isExcluded[account], "Wallet is already included in fee");
        _isExcluded[account] = true;
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

    function isUser(address account) internal view returns (bool) {
        if (!_isExcluded[account] && !_isServiceWallet[account]) {
            return true;
        } else {
            return false;
        }

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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 bFee;
        uint256 tFee;
        uint256 tAmount;
        if (isUser(sender) && isUser(recipient)) {
            tFee = amount * _userFee / 100;
        } else if (isUser(sender) && _isServiceWallet[recipient]) {
            require(amount <= MAX_SALE_AMOUNT, "amount exceeds maximum aloved for sale");
            if (_dailySales[sender].length == 4) {
                require(_dailySales[sender][0] < block.timestamp-86400, "Only 4 sells per day allowed");
                delete _dailySales[sender];
                _dailySales[sender][0] = block.timestamp;
            } else if (_dailySales[sender].length > 0) {
                require(_dailySales[sender][_dailySales[sender].length-1] < block.timestamp-3600, "1 hour delay between sales required");
                _dailySales[sender].push(block.timestamp);
            } else {
                _dailySales[sender].push(block.timestamp);
            }
            tFee = amount * _saleFees[_dailySales[sender].length-1] / 100;
            bFee = amount * _burnFee / 100;
        } else if (isUser(recipient) && _isServiceWallet[sender]) {
            if (_startBlock > 0 && block.number - _startBlock <=3 ) {
                require(amount <= MAX_START_BUY, "Amount exceeds max 3 blocks amount");
            }
            tFee = amount * _buyFee / 100;
            bFee = amount * _burnFee / 100;
        }

        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        if (bFee >0) {
            _totalSupply -= bFee;
            emit Transfer(sender, _burnWallet, bFee);
        }
        if (tFee > 0) {
            _balances[owner()] = _balances[owner()] + tFee;

        }
        tAmount = amount - bFee - tFee;

        _balances[recipient] += tAmount;

        emit Transfer(sender, recipient, tAmount);


    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyOwner {
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


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, _burnWallet, amount);


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


}