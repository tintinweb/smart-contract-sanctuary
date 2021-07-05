/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

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

interface IPancakePair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IMasterChef {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _ad) external view returns (uint256 _amount, uint256 _rewardDebt);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * Strategy contract interface
 */
interface IApyfierStrategy {
    function getName() external view returns (string memory);
    function getToken() external view returns (address);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;    
    function emergencyWithdraw() external;
    function balance() external view returns (uint256);
    function maintenanceValues() external view returns (uint256[] memory); // returns risk for risk depending maintenace
    function maintenance() external; // harvesting, etc...
    function setMaxSlippage(uint256 _maxSlippage) external;
    function setOwner(address _owner) external;
}


/**
 * Base class for strategy implementations
 */
abstract contract AbstractApyfierStrategy is IApyfierStrategy, Ownable {

    string internal name;
    IERC20 internal token;
    uint256 internal maxSlippage = 1e16; // 1%

    // used for conversions can be replaced by custom strategies
    address internal router = 0xe5638424FE334215bFD40B0eBbc087D7611bAD91; // v2 pcs router pancakeswap的router路由
    IERC20 internal wbnbToken = IERC20(0x20B4c15f8e2a4883587eDc90DF3e447F9B2a0BE0);//wbnb 只让内部访问

    constructor(string memory _name, IERC20 _token) {
        name = _name;
        token = _token;
    }

    function getName() override external view returns (string memory) {
        return name;
    }
    
    function getToken() override external view returns (address){
        return address(token);
    }
    
    function setOwner(address _owner) override external onlyOwner {
        transferOwnership(_owner);
    }

    function setMaxSlippage(uint256 _maxSlippage) override external onlyOwner {
        require(_maxSlippage >= 0 && _maxSlippage <= 1e18, '_maxSlippage');
        maxSlippage = _maxSlippage;
    }

    function _getDEXPrice(address _from, address _to, uint256 _amount) internal virtual view returns (uint256) {
        if (_amount == 0 || _from == _to) {
            return _amount;
        }        
        address[] memory _path =  _getSwapPath(_from, _to, false);//如果包含了wbnb的合约地址，就返回2个长度的， 如果不包含 就返回3个长度的。   
        uint256[] memory _amountsOut = IPancakeRouter(router).getAmountsOut(_amount, _path);//获取用_from的_amount数量去换取_to的值
        uint256 _amountOut = _amountsOut[_amountsOut.length - 1];//拿到可以兑换_to的数值
        delete _amountsOut;//_amountsOut 重置
        if (_path.length == 3) {//如果_from, 和_to 不包含wbnb的合约地址 就会返回3个长度的值
            delete _path;//重置_path           
            _path =  _getSwapPath(_from, _to, true);//再调用一次-- 拿到自己本身
            _amountsOut = IPancakeRouter(router).getAmountsOut(_amount, _path);//通过自己本身获取_amount，以及用_amount的数量可以换取多少个_to
            if (_amountsOut[_amountsOut.length - 1] > _amountOut) {//如果新的交易对的_to 大于_之前拿到的_to
                _amountOut = _amountsOut[_amountsOut.length - 1];//那么_amountOut 就是新的兑换值
            }
        }
        return _amountOut;  //拿到最大的兑换值
    }

    function _doDEXSwap(address _from, address _to, uint256 _amount, bool _isFromAmount) internal virtual {  
        if (_amount == 0 || _from == _to) {
            return;
        }
        address[] memory _path =  _getSwapPath(_from, _to, false);         
        uint256 _deadline = block.timestamp + 300;
        if (_isFromAmount) {
            uint256[] memory _amountsOut = IPancakeRouter(router).getAmountsOut(_amount, _path);
            uint256 _amountOut = _amountsOut[_amountsOut.length - 1];
            delete _amountsOut;
            if (_path.length == 3) {
                address[] memory _path2 = _getSwapPath(_from, _to, true);   
                _amountsOut = IPancakeRouter(router).getAmountsOut(_amount, _path2);
                if (_amountsOut[_amountsOut.length - 1] >= _amountOut) {
                    _amountOut = _amountsOut[_amountsOut.length - 1];
                    delete _amountsOut;
                    _path = _path2;
                }
            }
            uint256 _amountOutMin = _amountOut * (1e18 - maxSlippage) / 1e18;
            IPancakeRouter(router).swapExactTokensForTokens(_amount, _amountOutMin, _path, address(this), _deadline);
        } else {
            uint256[] memory _amountsIn = IPancakeRouter(router).getAmountsIn(_amount, _path);
            uint256 _amountIn = _amountsIn[0];
            delete _amountsIn;
            if (_path.length == 3) {
                address[] memory _path2 = _getSwapPath(_from, _to, true);   
                _amountsIn = IPancakeRouter(router).getAmountsIn(_amount, _path2);
                if (_amountsIn[0] <= _amountIn) {
                    _amountIn = _amountsIn[0];
                    delete _amountsIn;
                    _path = _path2;
                }
            }
            uint256 _amountInMax = _amountIn * (1e18 + maxSlippage) / 1e18;
            IPancakeRouter(router).swapTokensForExactTokens(_amount, _amountInMax, _path, address(this), _deadline);
        }
    }
        
    function _getSwapPath(address _from, address _to, bool _isDirect) private view returns (address[] memory) { //必定返回wbnb   
        bool _includesWBNB = _from == address(wbnbToken) || _to == address(wbnbToken);  //判断是否包含wbnb    
        address[] memory _path = new address[](_includesWBNB || _isDirect ? 2 : 3);//地址数组
        _path[0] = _from;//第一个为from
        _path[1] = (_includesWBNB || _isDirect) ? _to : address(wbnbToken);
        if (!_includesWBNB && !_isDirect) {
            _path[2] = _to;
        }
        return _path;
    }
    
    // can save your ass (TODO needs to be timelocked of course)
    function executeTransaction(address target, uint256 value, bytes memory callData) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, "reverted");
        return returnData;
    }
}

/**
 * Base test strategy implementation - configurable gain / loss
 */
contract AutoIncrementingTestStrategy is AbstractApyfierStrategy {

    constructor(IERC20 _token, string memory _name, uint256 _performancePerSecond) AbstractApyfierStrategy(_name, _token) {
        performancePerSecond = _performancePerSecond;
    }

    uint256 performancePerSecond;
    uint256 lastPersisted;

    function increment(uint256 _amount) external {
        persistBalance(); 
        TestToken(address(token)).mint(address(this), _amount);
    }
    function decrement(uint256 _amount) external {
        persistBalance(); 
        TestToken(address(token)).burn(address(this), _amount);
    }
    function deposit(uint256 _amount) override external {
        persistBalance();        
        token.transferFrom(msg.sender, address(this), _amount);
    }
    function balance() override public view returns (uint256) {
        uint256 _balance = token.balanceOf(address(this));
        if (lastPersisted > 0) {
            if (performancePerSecond > 1e18) {
                _balance += ((block.timestamp - lastPersisted) * (performancePerSecond - 1e18)) * _balance / 1e18;
            } else  if (performancePerSecond < 1e18) {
                _balance -= ((block.timestamp - lastPersisted) * (1e18 - performancePerSecond)) * _balance / 1e18;
            }            
        }  
        return _balance;      
    }
    function withdraw(uint256 _amount) override public onlyOwner {   
        persistBalance();   
        token.transfer(msg.sender, _amount);
    }
    function persistBalance() private {
        uint256 _balance = balance();
        uint256 _realBalance = token.balanceOf(address(this));
        if (_balance > _realBalance) {
            TestToken(address(token)).mint(address(this), _balance - _realBalance);
        } else if (_balance < _realBalance) {
            TestToken(address(token)).burn(address(this), _realBalance - _balance);
        }
        lastPersisted = block.timestamp;
    }

    function emergencyWithdraw() override external onlyOwner {
        withdraw(balance());
    }
    function maintenance() override external {
    }
    function maintenanceValues() override public pure returns (uint256[] memory) {
        uint256[] memory _result = new uint256[](2);
        return _result;
    }
}

contract Strategy1 is AutoIncrementingTestStrategy {
    constructor(IERC20 _token) AutoIncrementingTestStrategy(_token, "Best Strategy", 100000003e10) {
    }
}

contract Strategy2 is AutoIncrementingTestStrategy {
    constructor(IERC20 _token) AutoIncrementingTestStrategy(_token, "Winning Strategy", 100000002e10) {
    }
}

contract Strategy3 is AutoIncrementingTestStrategy {
    constructor(IERC20 _token) AutoIncrementingTestStrategy(_token, "Constant Strategy", 1e18) {
    }
}

contract Strategy4 is AutoIncrementingTestStrategy {
    constructor(IERC20 _token) AutoIncrementingTestStrategy(_token, "Constant Strategy 2", 1e18) {
    }
}

contract Strategy5 is AutoIncrementingTestStrategy {
    constructor(IERC20 _token) AutoIncrementingTestStrategy(_token, "Loosing Strategy", 99999999e10) {
    }
}

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TETO") {        
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }
}

contract AnotherTestToken is ERC20 {
    constructor() ERC20("Another Test Token", "ANOTETO") {        
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }
}

contract YetAnotherTestToken is ERC20 {
    constructor() ERC20("Yet Another Test Token", "YANOTETO") {        
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }
}

contract OneMoreTestToken is ERC20 {
    constructor() ERC20("One More Test Token", "OMTETO") {        
    }

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }
}