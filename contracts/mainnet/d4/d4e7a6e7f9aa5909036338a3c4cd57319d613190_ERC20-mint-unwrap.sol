// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Here is how to audit this contract.
 *
 * Step 1: get the totalSupply of wrapped tokens
 * 1. Navigate to etherscan.io
 * 2. Search for this contract address
 * 3. Click on the tab labelled `Contract`
 * 4. Click on the button labelled `Read Contract`
 * 5. Click on `totalSupply`
 *
 * Step 2: get the amount of underlying tokens owned by this contract
 * 1. Navigate to etherscan.io
 * 2. Search for the underlying token address
 * 3. Click on the tab labelled `Contract`
 * 4. Click on the button labelled `Read Contract`
 * 5. Click on `balanceOf`
 * 6. Enter this contract address, then click on `Query`.
 *
 * if step 1 equals step 2, then...
 *   the amount of underlying tokens owned by this contract
 * equals
 *   the amount of wrapped tokens that got minted, and life is good.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    address private _owner;
    uint256 private _totalSupply;
    address private _underlying;

    bytes32[] private _transactions;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }    

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * `underlying` is the other ERC20 token address that is bridged/wrapped by
     * this contract.
     *
     * All of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, address underlying) {
        _owner = _msgSender();
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _underlying = underlying;
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
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the underlying ERC20 token address that is bridged/wrapped
     * by this contract.
     */
    function underlying() public view returns (address) {
        return _underlying;
    }

    /**
     * @dev Returns true if the specified transaction got minted, otherwise
     * false.
     */
    function minted(bytes32 transaction) public view returns (bool) {
        return _minted(transaction);
    }    

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * @dev Creates `amount` tokens and assigns them to `recipient`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * 
     * Requirements:
     *
     * - cannot get called by anyone but the owner address.
     * - `transaction` cannot be zero.
     * - `recipient` cannot be the zero address.
     * - `transaction` cannot exist (if it does, the contract does not mistakenly mint again)
     */    
    function mint(bytes32 transaction, address recipient, uint256 amount) public virtual onlyOwner returns (bool) {
        require(transaction != bytes32(0), "ERC20: transaction is zero");
        require(recipient != address(0), "ERC20: mint to the zero address");
        require(_minted(transaction) == false, "ERC20: transaction has been minted");

        _mint(recipient, amount);

        _transactions.push(transaction);
        
        return true;
    }

    /**
     * @dev Transfers `amount` of the underlying ERC20 token from this
     * contract address to `msg.sender`, then destroys `amount` wrapped
     * tokens from `msg.sender`, reducing the total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `msg.sender` must have at least `amount` tokens.
     */
    function unwrap(uint256 amount) public virtual returns (bool) {      
        require(_balances[_msgSender()] >= amount, "ERC20: unwrap amount exceeds balance");

        require(ERC20(_underlying).transfer(_msgSender(), amount), "ERC20: underlying.transfer() returned false");

        _burn(_msgSender(), amount);
        
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
     * - `source` and `recipient` cannot be the zero address.
     * - `source` must have a balance of at least `amount`.
     * - the caller must have allowance for `source`'s tokens of at least
     *   `amount`.
     */
    function transferFrom(address source, address recipient, uint256 amount) public virtual override returns (bool) {
        require(source != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(_balances[source] >= amount, "ERC20: transfer amount exceeds balance");

        if (source != _msgSender() && _allowances[source][_msgSender()] != uint(-1)) {           
            require(_allowances[source][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(source, _msgSender(), _allowances[source][_msgSender()].sub(amount));
        }

        _transfer(source, recipient, amount);
        
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Returns true if the specified transaction got minted, otherwise
     * false.
     */
    function _minted(bytes32 transaction) internal view returns (bool) {
        for (uint i; i < _transactions.length; i++) {
            if (_transactions[i] == transaction) {
                return true;
            }
        }
        return false;
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }    

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`'s tokens.
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
}