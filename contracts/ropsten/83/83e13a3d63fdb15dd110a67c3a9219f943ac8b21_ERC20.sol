pragma solidity >=0.5.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

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




contract Inventory {
    
    using SafeMath for uint;

    
    address payable owner;
    event addingSmallSizeInventory(uint amount);
    event addingMediumSizeInventory(uint amount);
    event addingLargeSizeInventory(uint amount);
    event addingxLargeSizeInventory(uint amount);
    event addingxxLargeSizeInventory(uint amount);
    event shippingstatuschange(bool status);
    event boughtsmallsizeamount(address _address, uint amount, uint orderNum);
    event boughtmediumsizeamount(address _address, uint amount, uint orderNum);
    event boughtlargesizeamount(address _address, uint amount, uint orderNum);
    event boughtxlargesizeamount(address _address, uint amount, uint orderNum);
    event boughtxxlargesizeamount(address _address, uint amount, uint orderNum);
    event TokenSentWithClothingBuyOrder(address _address, uint amount);
    event bought (uint256 TotalBasketAmount);
    event sizesbought (uint256 xbought);
    event Ratechange (uint256 Rate);
    event percentChange(uint256 percentup);
    event currentsupply(uint256 cccbought);
    
    struct OrderInfo {
    uint OrderNum;
    bool Shipped;
    uint small_sizes;
    uint medium_sizes;
    uint large_sizes;
    uint xlarge_sizes;
    uint xxlarge_sizes;
    
}

    struct sizes {
        uint amount;
    }
    
  
    
   

    mapping(address => OrderInfo) order_info;
  
    
    
    
    
     
    uint256 public Rate;
    uint256 public NewRate;
    uint256 public percentageIncrease;
     
    
    
    sizes public smallSizes;
    sizes public mediumSizes;
    sizes public largeSizes;
    sizes public xlargeSizes;
    sizes public xxlargeSizes;
    
    
    
    
    constructor() public {
        owner = msg.sender;
        
        smallSizes.amount = 20;
        mediumSizes.amount = 20 ;
        largeSizes.amount = 20;
        xlargeSizes.amount = 20;
        xxlargeSizes.amount = 20;
       
        
       
        
    }
    
    function addSmallSizeInventory(uint _amount) public{
        
        
        require(msg.sender == owner, "this function is restricted to the owner");
        sizes storage smallSizes_ = smallSizes;
        smallSizes_.amount += _amount; 
        emit addingSmallSizeInventory(_amount);
        
    }
    
    
    function addMediumSizeInventory(uint _amount) public {
        
        require(msg.sender == owner, "this function is restricted to the owner");
        sizes storage mediumSizes_ = mediumSizes;
        mediumSizes_.amount += _amount;
        emit addingMediumSizeInventory(_amount);
        
    }

function addLargeSizeInventory(uint _amount) public {
        require(msg.sender == owner, "this function is restricted to the owner");
        sizes storage largeSizes_ = largeSizes;
        largeSizes_.amount += _amount;
        emit addingLargeSizeInventory(_amount);
    }
    
function addxLargeSizeInventory(uint _amount) public {
        require(msg.sender == owner, "this function is restricted to the owner");
        sizes storage xlargeSizes_ = xlargeSizes;
        xlargeSizes_.amount += _amount;
        emit addingxLargeSizeInventory(_amount);
    }

function addxxLargeSizeInventory(uint _amount) public {
        require(msg.sender == owner, "this function is restricted to the owner");
        sizes storage xxlargeSizes_ = xxlargeSizes;
        xxlargeSizes_.amount += _amount;
        emit addingLargeSizeInventory(_amount);
    }
    
   
    
}



contract ERC20 is Context, IERC20, Inventory {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 0;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
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

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
 
     
    
    receive() external payable {
            
        uint balmsg = msg.sender.balance;
        balmsg = msg.sender.balance.add(msg.value);
            
        }
    

    

    
   
    
    function basket( address _address, uint256 _small_sizes, uint256 _medium_sizes, uint256 _large_sizes, uint256 _xlarge_sizes, uint256 _xxlarge_sizes) internal {
        
       
       sizes storage smallSizes_ = smallSizes;
       sizes storage mediumSizes_ = mediumSizes;
       sizes storage largeSizes_ = largeSizes;
       sizes storage xlargeSizes_ = xlargeSizes;
       sizes storage xxlargeSizes_ = xxlargeSizes;
       
       
        
        
        OrderInfo storage buyer = order_info[_address];
        
         
       
        
        
        /** approve(_address, _small_sizes); */
        
        
             
        if (smallSizes_.amount < _small_sizes){
            revert("Amount is Greater Than Supply");
            
        } else {
        smallSizes_.amount -= _small_sizes; 
        }
        buyer.small_sizes += _small_sizes;
        _mint( _address, _small_sizes);
        emit boughtsmallsizeamount(_address, _small_sizes, block.number);
        
        
        
        /**medium sizes*/
        
        if (mediumSizes_.amount < _medium_sizes){
            revert("Amount is Greator Than Supply");
        } else {
        mediumSizes_.amount -= _medium_sizes;
        }
        buyer.medium_sizes += _medium_sizes;
        _mint(_address, _medium_sizes);
        emit boughtmediumsizeamount(_address, _medium_sizes, block.number);
        
        
        /**large sizes*/
        
        if (largeSizes_.amount < _large_sizes){
            revert("Amount is Greater Than Supply");
        } else {
        largeSizes_.amount -= _large_sizes;
        }
        buyer.large_sizes += _large_sizes;
        _mint(_address, _large_sizes);
        emit boughtlargesizeamount(_address, _large_sizes, block.number);
        
        
        
        /**Xlarge sizes*/
        
          if (xlargeSizes_.amount < _xlarge_sizes){
            revert("Amount is Greater Than Supply");
            
        } else {
        xlargeSizes_.amount -= _xlarge_sizes;
        }
        buyer.xlarge_sizes += _xlarge_sizes;
        _mint(_address, _xlarge_sizes);
        emit boughtxlargesizeamount(_address, _xlarge_sizes, block.number);
        
        
        
        /**XXLarge sizes*/
        
        
          if (xxlargeSizes_.amount < _xxlarge_sizes){
            revert("Amount is Greater Than Supply");
            
        } else {
        xxlargeSizes_.amount -= _xxlarge_sizes;
        }
        buyer.xxlarge_sizes += _xxlarge_sizes;
        _mint(_address, _xxlarge_sizes);
        emit boughtxxlargesizeamount(_address, _xxlarge_sizes, block.number);
        
        buyer.OrderNum = block.number;
        
        
}

   function exchangeETH(uint256 ssizes, uint256 msizes, uint256 lsizes, uint256 xlsizes, uint256 xxlsizes) public payable returns(uint256, uint256) {
         
        uint256 cbought;
        uint256 ccbought;
        uint256 cccbought;
        uint256 xbought;
        uint256 percentup;
        uint256 TotalBasketAmount;
        uint256 balsend;
        
        basket(msg.sender, ssizes, msizes, lsizes, xlsizes, xxlsizes); 
        cbought =  (ssizes + msizes);
        ccbought = (lsizes + xlsizes + xxlsizes);
        xbought = (cbought.add(ccbought));
        cccbought = (smallSizes.amount + mediumSizes.amount + largeSizes.amount + xlargeSizes.amount + xxlargeSizes.amount);
        
        
        percentup = xbought.div(cccbought);

    
        Rate = 0.08 ether;
        NewRate = Rate + percentup ;
        
        
    
        TotalBasketAmount = (xbought * NewRate);
        
        
        balsend = msg.sender.balance;
            
        require(balsend >= TotalBasketAmount , "You don't have enough Ether: Aborted");
        require(msg.value >= TotalBasketAmount, "Your not sending the correct amount to cover your balance");
        
        
        emit percentChange(NewRate);
        emit currentsupply(cccbought);
        emit sizesbought( xbought);
        emit bought(TotalBasketAmount);
        owner.transfer(msg.value);
        
        return(msg.value, TotalBasketAmount);
        
   }
        

    
    function shipping(address _address, bool _shipping) public {
        
        OrderInfo storage buyer = order_info[_address];
        
        buyer.Shipped = _shipping;
        
        emit shippingstatuschange(_shipping);
    }
    
    function getOrderInfo(address ins) view public returns ( uint, uint, uint,uint, uint, uint, bool) {
        return ( order_info[ins].small_sizes, order_info[ins].medium_sizes,  order_info[ins].large_sizes, order_info[ins].xlarge_sizes, order_info[ins].xxlarge_sizes, order_info[ins].OrderNum, order_info[ins].Shipped);
    }
    
}