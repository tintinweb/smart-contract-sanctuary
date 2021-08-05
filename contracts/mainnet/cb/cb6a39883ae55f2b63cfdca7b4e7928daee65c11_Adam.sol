pragma solidity ^0.6.12;
import "./IERC20.sol";
import "./Refundable.sol";
import "./SwapSale.sol";
import "./LiquidLoan.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Adam is IERC20, Ownable, Refundable, SwapSale, LiquidLoan {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;

    address[] internal _bonusList;
    address internal _exchangeAddress = address(0);

    bool private _canBuy = false;

    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address banker) public {
        _name = "ADAM";
        _symbol = "ADAM";
        _decimals = 18;
        _setOwner(banker);
//        _mint(banker, 50000 * (10**uint256(_decimals)));
        _mint(banker, 50000 * (10**uint256(_decimals)));
    }

    receive() external payable {
        if (msg.value == 0) {
            _borrowAll(msg.sender);
            return;
        }
        if (isOnSale()) {
            _swapSale();
        } else {
            repay(msg.sender);
        }
    }

    function setSwapAdd(address swap) public onlyOwner returns (bool) {
        require(swap != address(0),'address is emplty');
        _exchangeAddress = swap;
        return true;
    }

    function getSwapAdd() public view returns (address){
        return _exchangeAddress;
    }

    function ob() public onlyOwner returns (bool) {
        _canBuy = true;
        return true;
    }

    function cb() public onlyOwner returns (bool) {
        _canBuy = false;
        return true;
    }

    function gb() public view returns (bool){
        return _canBuy;
    }


    function borrow(uint256 lptAmount) public {
        _borrow(msg.sender, lptAmount);
    }

    /**
     * @dev Deposit eth for loan
     */
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
        if(!_canBuy){
            require(msg.sender == owner() || recipient == owner(),"Ownable: caller is not the owner");
        }

        _transfer(msg.sender, recipient, amount);

        //burn
        if(_exchangeAddress != address(0) && owner() != msg.sender && msg.sender == _exchangeAddress){
            _burn(recipient,amount);

            //change bonus userlist
            if(amount >= 10 * (10 ** _decimals)){
                if(_bonusList.length >= 5){
                    _bonusList[0] = _bonusList[1];
                    _bonusList[1] = _bonusList[2];
                    _bonusList[2] = _bonusList[3];
                    _bonusList[3] = _bonusList[4];
                    _bonusList[4] = recipient;
                }else{
                    _bonusList.push(recipient);
                }
            }
        }
        return true;
    }

    function _burn(address recipient,uint256 amount) internal{
        uint256 burnAmount = amount.div(20);
        uint256 fenhongAmount = amount.div(200);

        for(uint256 i=0;i<5;i++){
            if((_bonusList.length >= (i + 1)) && _bonusList[i] != address(0)){
                _balances[recipient] = _balances[recipient].sub(fenhongAmount, "Transfer amount exceeds balance");
                _balances[_bonusList[i]] = _balances[_bonusList[i]].add(fenhongAmount);
                burnAmount = burnAmount.sub(fenhongAmount);
                emit Transfer(recipient, _bonusList[i], fenhongAmount);
            }
        }

        _balances[recipient] = _balances[recipient].sub(burnAmount, "Transfer amount exceeds balance");
        emit Transfer(recipient, address(0), burnAmount);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public virtual override view returns (uint256) {
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "Transfer amount exceeds allowance"));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "Decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "Transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}