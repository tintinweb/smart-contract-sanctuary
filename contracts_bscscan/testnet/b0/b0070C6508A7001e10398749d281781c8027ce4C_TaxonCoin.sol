/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT
// File: IRouter.sol


pragma solidity ^0.8.0;
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
// File: IFactory.sol


pragma solidity ^0.8.0;

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: IBEP20.sol


pragma solidity ^0.8.0;
interface IBEP20 {


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: IERC20.sol


pragma solidity ^0.8.0;
interface IERC20 {


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: IERC20Metadata.sol



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

// File: Context.sol


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }


    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: ERC20.sol


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

// File: ERC20Burnable.sol



pragma solidity ^0.8.0;



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
// File: Ownable.sol


pragma solidity ^0.8.0;


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


    constructor() {
        _setOwner(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


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
// File: Address.sol


pragma solidity ^0.8.0;

library Address {

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}
// File: TaxonCoin.sol


pragma solidity ^0.8.0;









contract TaxonCoin is Context, Ownable, IERC20 {
    using Address for address;
    using Address for address payable;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;
    
    mapping(address => bool) private _isBadActor;


    mapping (address => bool) private _isExcludedFromFee;


    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 3100000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;


    string private _name = "TaxonCoin";
    string private _symbol = "TAXON";
    uint8 private _decimals = 18;

    struct feeRatesStruct {
      uint256 taxFee;
	  uint256 burnFee;
	  uint256 airdropFee;
      uint256 marketingFee;      
      uint256 liquidityFee;
      uint256 swapFee;
      uint256 totFees;
    }
    
    feeRatesStruct public buyFees = feeRatesStruct(
     {taxFee: 0,
	  burnFee: 5000,
      airdropFee: 2500,
	  liquidityFee: 2500,
      marketingFee: 0, 
      swapFee: 10000, // burnFee+airdropFee+liquidityFee+marketingFee
      totFees: 2
    });

    feeRatesStruct public sellFees = feeRatesStruct(
     {taxFee: 0,
	  burnFee: 5000,
      airdropFee: 2500,
	  liquidityFee: 2500,
      marketingFee: 0, 
      swapFee: 10000, // burnFee+airdropFee+liquidityFee+marketingFee
      totFees: 2
    });

    feeRatesStruct private appliedFees = buyFees; //default value
    feeRatesStruct private previousFees;

    struct antiwhale {
      uint256 selling_threshold;//this is value/1000 %
      uint256 extra_tax; //this is value %
    }

    antiwhale[3] public antiwhale_measures;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rFee;
      uint256 rSwap;
      uint256 tTransferAmount;
      uint256 tFee;
      uint256 tSwap;
    }

    
    uint256 public maxSellPerDay = _tTotal/1000;
    
    address payable public burnWallet = payable(0x7B47066C36f4668916dD7047060010BAdF9099dB);
    address payable public marketingWallet = payable(0x7B47066C36f4668916dD7047060010BAdF9099dB);
    address payable public liquidityWallet = payable(0x581BCaf2A3a65B84cb03b2C811C1BB16336564e4);
    address payable public airdropWallet = payable(0x581BCaf2A3a65B84cb03b2C811C1BB16336564e4);
    

    IRouter public pancakeRouter;
    address public pancakePair;
    IERC20 public ERC20Token;
    
    bool inSwap;
    bool public swapEnabled = true;
    uint256 private minTokensToSwap = 40000 * 10**18;
    uint256 public maxTxAmount = _tTotal/100;


    event swapEnabledUpdated(bool enabled);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;
        

        IRouter _pancakeRouter = IRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        pancakePair = IFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[burnWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[liquidityWallet] = true;
        _isExcludedFromFee[airdropWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        
        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*25/100000, extra_tax: 1});//0.025% of initial supply
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*50/100000, extra_tax: 2});//0.05% of initial supply
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*75/100000, extra_tax: 3});//0.075% of initial supply

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }


    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }


    function totalFeesCharged() public view returns (uint256) {
        return _tFeeTotal;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory s = _getValues(tAmount, false);
        _rOwned[sender] -= s.rAmount;
        _rTotal -= s.rAmount;
        _tFeeTotal += tAmount;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            valuesFromGetValues memory s = _getValues(tAmount, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }


    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function excludeFromReward(address[] memory accounts) public onlyOwner() {
        uint256 length = accounts.length;
        for(uint256 i=0;i<length;i++)
        {
        require(!_isExcluded[accounts[i]], "Account is already excluded");
        if(_rOwned[accounts[i]] > 0) {
            _tOwned[accounts[i]] = tokenFromReflection(_rOwned[accounts[i]]);
        }
        _isExcluded[accounts[i]] = true;
        _excluded.push(accounts[i]);
        }
    }


    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
     //to recieve ETH from pancakeRouter when swaping
    receive() external payable {}


     function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal     = _rTotal-rFee;
        _tFeeTotal  = _tFeeTotal+tFee;
    }


    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rFee, to_return.rSwap) = _getRValues(to_return,tAmount, takeFee, _getRate());
        return to_return;
    }


    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tFee = tAmount*appliedFees.totFees*appliedFees.taxFee/1000000;
        s.tSwap = tAmount*appliedFees.totFees*appliedFees.swapFee/1000000;
        s.tTransferAmount = tAmount-s.tFee-s.tSwap;
        return s;
    }


    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount*currentRate;
        if(!takeFee)
        {
            return (rAmount,rAmount,0,0);
        }
        uint256 rFee = s.tFee*currentRate;
        uint256 rSwap = s.tSwap*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rSwap;
        return (rAmount, rTransferAmount, rFee, rSwap);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }


    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 length = _excluded.length;    
        for (uint256 i = 0; i < length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -=_rOwned[_excluded[i]];
            tSupply -=_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeSwapFees(uint256 rSwap, uint256 tSwap) private {

        _rOwned[address(this)] +=rSwap;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] +=tSwap;
    }
    
    
            //////////////////////////
           /// Setters functions  ///
          //////////////////////////
    function setBurnWallet(address payable _address) external onlyOwner returns (bool){
        burnWallet = _address;
        _isExcludedFromFee[burnWallet] = true;
        return true;
    }    
   function setMarketingWallet(address payable _address) external onlyOwner returns (bool){
        marketingWallet = _address;
        _isExcludedFromFee[marketingWallet] = true;
        return true;
    }
    function setLiquidityWallet(address payable _address) external onlyOwner returns (bool){
        liquidityWallet = _address;
        _isExcludedFromFee[liquidityWallet] = true;
        return true;
    }
    function setAirdropWallet(address payable _address) external onlyOwner returns (bool){
        airdropWallet = _address;
        _isExcludedFromFee[airdropWallet] = true;
        return true;
    }
       
    function setBuyFees(uint256 taxFee, uint256 burnFee, uint256 airdropFee, uint256 marketingFee, uint256 liquidityFee) external onlyOwner{
        buyFees.taxFee = taxFee;
		buyFees.burnFee = burnFee;
		buyFees.airdropFee = airdropFee;
        buyFees.marketingFee = marketingFee;      
        buyFees.liquidityFee= liquidityFee;
        buyFees.swapFee = marketingFee+airdropFee+burnFee+liquidityFee;
        require(buyFees.swapFee+buyFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setSellFees(uint256 sellTaxFee, uint256 sellBurnFee, uint256 sellAirdropFee, uint256 sellMarketingFee, uint256 sellLiquidityFee) external onlyOwner{
        sellFees.taxFee = sellTaxFee;
		sellFees.burnFee = sellBurnFee;
		sellFees.airdropFee = sellAirdropFee; 
        sellFees.marketingFee = sellMarketingFee;               
        sellFees.liquidityFee = sellLiquidityFee;        
        sellFees.swapFee = sellMarketingFee+sellAirdropFee+sellBurnFee+sellLiquidityFee;
        require(sellFees.swapFee+sellFees.taxFee == 10000, "sum of all percentages should be 10000");
    }
    
    function setTotalBuyFees(uint256 _totFees) external onlyOwner{
        buyFees.totFees = _totFees;
    }
    
    function setTotalSellFees(uint256 _totSellFees) external onlyOwner{
        sellFees.totFees = _totSellFees;
    }
    
    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellPerDay = amount * 10**9;
    }
    
    function setAntiwhaleMeasure(uint256[3] memory selling_thresholds, uint256[3] memory extra_taxes ) external onlyOwner{
        //values of selling_threshold (are values in input)/1000 % of total supply , extra taxes are expressed in %
        antiwhale_measures[0] = antiwhale({selling_threshold: _tTotal*selling_thresholds[0]/100000 , extra_tax: extra_taxes[0]});
        antiwhale_measures[1] = antiwhale({selling_threshold: _tTotal*selling_thresholds[1]/100000 , extra_tax: extra_taxes[1]});
        antiwhale_measures[2] = antiwhale({selling_threshold: _tTotal*selling_thresholds[2]/100000 , extra_tax: extra_taxes[2]});
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit swapEnabledUpdated(_enabled);
    }
    
    function setNumTokensTosSwap(uint256 amount) external onlyOwner{
        minTokensToSwap = amount * 10**9;
    }
    
    function setMaxTxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**9;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

        function getAntiwhaleFee(uint256 amount) internal view returns(uint256 sell_tax) {
    
        if(amount < antiwhale_measures[0].selling_threshold) {
          sell_tax=0;
        }
        else if(amount < antiwhale_measures[1].selling_threshold) {
          sell_tax = antiwhale_measures[0].extra_tax;
        }
        else if(amount < antiwhale_measures[2].selling_threshold) {
          sell_tax = antiwhale_measures[1].extra_tax;
        }
        else { sell_tax = antiwhale_measures[2].extra_tax; }

      return sell_tax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBadActor[from] && !_isBadActor[to], "Bots are not allowed");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(amount <= maxTxAmount, 'you are exceeding maxTxAmount');
        }
        
        if(!_isExcludedFromFee[from] && to == pancakePair){
            if(block.timestamp < _firstSell[from]+24 * 1 hours){
                require(_totSells[from]+amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _totSells[from] += amount;
            }
            else{
                require(amount <= maxSellPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[from] = block.timestamp;
                _totSells[from] = amount;
            }
                
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= minTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwap &&
            from != pancakePair &&
            swapEnabled
        ) {
            contractTokenBalance = minTokensToSwap;
            swapAndSendToFees(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        bool isSale = false;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else
        {
            if(to == pancakePair){
            isSale = true;
            }
        }
             
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee, isSale);
    }
    
    function swapAndSendToFees(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 transferBalance = address(this).balance-initialBalance;
        liquidityWallet.sendValue(transferBalance*appliedFees.liquidityFee/appliedFees.swapFee);
        airdropWallet.sendValue(transferBalance*appliedFees.airdropFee/appliedFees.swapFee);
        burnWallet.sendValue(transferBalance*appliedFees.burnFee/appliedFees.swapFee);
        marketingWallet.sendValue(address(this).balance);

    }
	
	function airdrop( address[] calldata _contributors, uint256[] calldata _balances) external   {
		uint8 i = 0;
		for (i; i < _contributors.length; i++) {
		_transfer(msg.sender,_contributors[i], _balances[i]);
		}
	}
	
	function preSale( address[] calldata _contributors, uint256[] calldata _balances) external   {
		uint8 i = 0;
		for (i; i < _contributors.length; i++) {
		_transfer(msg.sender,_contributors[i], _balances[i]);
		}
	}


    function swapTokensForBNB(uint256 tokenAmount) private lockTheSwap {

        // generate the pancakeswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        if(allowance(address(this), address(pancakeRouter)) < tokenAmount) {
          _approve(address(this), address(pancakeRouter), ~uint256(0));
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }


    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSale) private {
        if(takeFee){
            if(isSale)
            {
            appliedFees = sellFees;
            appliedFees.totFees += getAntiwhaleFee(_totSells[sender]);
            }
            else
            {
            appliedFees = buyFees;
            }
        }
        
        valuesFromGetValues memory s = _getValues(amount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -=amount;
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }
        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] +=s.rTransferAmount;
        
        if(takeFee)
            {
             _takeSwapFees(s.rSwap,s.tSwap);
             _reflectFee(s.rFee, s.tFee);
             emit Transfer(sender, address(this), s.tSwap);
            }
        emit Transfer(sender, recipient, s.tTransferAmount);
    }
    
            //////////////////////////
           /// Emergency functions //
          //////////////////////////


    function rescueBNBFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
	function rescueETHTokenFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
	function rescueERC20TokenFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
		ERC20Token.transfer(_owner,address(this).balance);
    }

    
    function manualSwap() external onlyOwner{
        uint256 tokensToSwap = balanceOf(address(this));
        swapTokensForBNB(tokensToSwap);
    }
    
    function manualSend() external onlyOwner{
        swapAndSendToFees(balanceOf(address(this)));
    }


    // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool isBadActor) external onlyOwner{
        _isBadActor[account] = isBadActor;
    }
    
    function checkBadActor(address account) public view returns(bool){
        return _isBadActor[account];
    }
    
    function setRouterAddress(address newRouter) external onlyOwner {
        require(address(pancakeRouter) != newRouter, 'Router already set');
        //give the option to change the router down the line 
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        //checks if pair already exists
        if (get_pair == address(0)) {
            pancakePair = IFactory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pancakePair = get_pair;
        }
        pancakeRouter = _newRouter;
    }
    
}