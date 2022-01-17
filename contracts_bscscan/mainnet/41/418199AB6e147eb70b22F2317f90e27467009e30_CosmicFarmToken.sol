/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

/**

* @dev 宇宙农场cosmic farm智能合约 波场链
中文名称：宇宙农场
英文名称：cosmic farm
代币名称：cf
发行量：2626600
发行公链：波场链
 */

contract CosmicFarmToken {
    using SafeMath for uint256;

    string private _name = "Cosmic Farm"; //  token name
    string private _symbol = "CF"; //  token symbol
    uint8 private _decimals = 18; //  token decimals

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply; // 已经发行总量
    uint256 public _maxSupply = 13000000 * 10**uint256(_decimals); //最大发行总量
    uint256 public _minSupply = 6000000 * 10**uint256(_decimals); //最小发行总量
    uint256 public _feeCount = 0; //已经通缩的总量
    uint256 public _FeeRatio = 10; //  通缩比例10%

    address _Owner = address(0); //合约所有者
    address[3] _FeeReceiver = [address(0), address(0), address(0)]; //手续费接收地址
    address _StakeContract = address(0); //质押挖矿合约地址
    address _TradeContract = address(0); //买卖cf代币合约地址

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event DistributeToken(address indexed to, uint256 value); // 分发代币事件

    modifier isOwner() {
        assert(_Owner == msg.sender);
        _;
    }

    constructor() public {
        _Owner = msg.sender;
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
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-maxSupply}.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-Owner}.
     */
    function Owner() public view returns (address) {
        return _Owner;
    }

    /**
     * @dev See {IERC20-StakeContract}.
     */
    function StakeContract() public view returns (address) {
        return _StakeContract;
    }

    /**
     * @dev See {IERC20-TradeContract}.
     */
    function TradeContract() public view returns (address) {
        return _TradeContract;
    }

    /**
     * @dev See {IERC20-FeeRatio}.
     */
    function FeeRatio() public view returns (uint256) {
        return _FeeRatio;
    }

    /**
     * @dev See {IERC20-FeeReceiver}.
     */
    function FeeReceiver(uint8 _type) public view returns (address) {
        require(_type < uint8(3));

        return _FeeReceiver[_type];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
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
    ) internal {
        require(amount > 0, "ERC20: transfer amount is zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        //检查发送者是否拥有足够余额
        require(
            _balances[sender].sub(amount) >= 0,
            "ERC20: transfer amount is more than balance"
        );
        //检查是否溢出
        require(
            _balances[recipient].add(amount) > _balances[recipient],
            "ERC20: transfer amount is wrong"
        );

        //从发送者减掉发送额
        _balances[sender] = _balances[sender].sub(amount);

        uint256 feeRatio = 0;

        //发送者或者质押者为质押合约则不扣手续费
        //if (_StakeContract != address(0) && (sender == _StakeContract || recipient == _StakeContract)) feeRatio = 0;

        //从交易合约购买代币时扣除手续费
        if (
            _TradeContract != address(0) && (sender == _TradeContract) /* || recipient == _TradeContract*/
        ) feeRatio = _FeeRatio;
        else feeRatio = 0;

        //通缩达到最小总量后，不再通缩
        if (feeRatio > 0) {
            if (
                _feeCount.add(amount.mul(feeRatio).div(100)) >
                _maxSupply.sub(_minSupply)
            ) feeRatio = 0;
            else _feeCount = _feeCount.add(amount.mul(feeRatio).div(100));
        }

        //给接收者加上扣除手续费后数量
        _balances[recipient] = _balances[recipient].add(
            amount.mul(100 - feeRatio).div(100)
        );

        //发送手续费
        if (feeRatio > 0) {
            //%2分给资金池股东
            if (_FeeReceiver[0] != address(0))
                _balances[_FeeReceiver[0]] = _balances[_FeeReceiver[0]].add(
                    amount.mul(2).div(100)
                );
            //3%分给基金账户
            if (_FeeReceiver[1] != address(0))
                _balances[_FeeReceiver[1]] = _balances[_FeeReceiver[1]].add(
                    amount.mul(3).div(100)
                );
            //5%分给资金池底池回流
            if (_FeeReceiver[2] != address(0))
                _balances[_FeeReceiver[2]] = _balances[_FeeReceiver[2]].add(
                    amount.mul(5).div(100)
                );
        }

        emit Transfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(amount)
        );
    }

    function setOwner(address _addr) public isOwner {
        _Owner = _addr;
    }

    function setFeeRatio(uint256 _value) public isOwner {
        require(uint256(100).sub(_value) >= 0);

        _FeeRatio = _value;
    }

    function setFeeReceiver(address _addr, uint8 _type) public isOwner {
        require(_type < uint8(3));

        _FeeReceiver[_type] = _addr;
    }

    function setStakeContract(address _addr) public isOwner {
        _StakeContract = _addr;
    }

    function setTradeContract(address _addr) public isOwner {
        _TradeContract = _addr;
    }

    //分发指定数量cf代币给指定地址
    function distributeToken(address _to, uint256 _value) public {
        require(msg.sender == _Owner || (_StakeContract != address(0) && msg.sender == _StakeContract));
        require(_to != address(0));
        require(_value > uint256(0));
        require(_totalSupply.add(_value) <= _maxSupply);

        _mint(_to, _value);

        emit DistributeToken(_to, _value);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}