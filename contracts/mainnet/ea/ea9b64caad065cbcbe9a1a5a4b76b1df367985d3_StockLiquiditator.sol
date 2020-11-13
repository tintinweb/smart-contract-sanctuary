pragma solidity 0.5.12;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view  returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public   returns (bool) {
        _approve(_msgSender(), spender, amount);
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
    function _mint(address account, uint256 amount) internal  {
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
    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");


        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
}

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract StockLiquiditator is ERC20,ERC20Detailed
{

    using SafeMath for uint256;
    
    uint256 public cashDecimals;
    uint256 public stockTokenMultiplier;
    
    ERC20Detailed internal cash;
    ERC20Detailed internal stockToken;
    
    uint256 public stockToCashRate;
    uint256 public poolToCashRate;
    uint256 public cashValauationCap;
    
    string public url;
    
    event UrlUpdated(string _url);
    event ValuationCapUpdated(uint256 cashCap);
    event OwnerChanged(address indexed newOwner);
    event PoolRateUpdated(uint256 poolrate);
    event PoolTokensMinted(address indexed user,uint256 inputCashAmount,uint256 mintedPoolAmount);
    event PoolTokensBurnt(address indexed user,uint256 burntPoolAmount,uint256 outputStockAmount,uint256 outputCashAmount);
    event StockTokensRedeemed(address indexed user,uint256 redeemedStockToken,uint256 outputCashAmount);
    
    function () external payable {  //fallback function
        
    }
    
    address payable public owner;
    
    modifier onlyOwner() {
        require (msg.sender == owner,"Account not Owner");
        _;
    }
        
    constructor (address cashAddress,address stockTokenAddress,uint256 _stockToCashRate,uint256 cashCap,string memory name,string memory symbol,string memory _url) 
    public ERC20Detailed( name, symbol, 18)  
    {
        owner = msg.sender;
        require(stockTokenAddress != address(0), "stockToken is the zero address");
        require(cashAddress != address(0), "cash is the zero address");
        cash = ERC20Detailed(cashAddress);
        stockToken = ERC20Detailed(stockTokenAddress);
        cashDecimals = cash.decimals();
        stockTokenMultiplier = (10**uint256(stockToken.decimals()));
        stockToCashRate = (10**(cashDecimals)).mul(_stockToCashRate);
        updatePoolRate();
        updateCashValuationCap(cashCap);
        updateURL(_url);
    }
    
    function updateURL(string memory _url) public onlyOwner returns(string memory){
        url=_url;
        emit UrlUpdated(_url);
        return url;
    }
    
    function updateCashValuationCap(uint256 cashCap) public onlyOwner returns(uint256){
        cashValauationCap=cashCap;
        emit ValuationCapUpdated(cashCap);
        return cashValauationCap;
    }
    
    function changeOwner(address payable newOwner) external onlyOwner {
        owner=newOwner;
        emit OwnerChanged(newOwner);
    }
    
    function stockTokenAddress() public view returns (address) {
        return address(stockToken);
    }
    
    function _preValidateData(address beneficiary, uint256 amount) internal pure {
        require(beneficiary != address(0), "Beneficiary can't be zero address");
        require(amount != 0, "amount can't be 0");
    }
    
    function contractCashBalance() public view returns(uint256 cashBalance){
        return cash.balanceOf(address(this));
    } 
    
    function contractStockTokenBalance() public view returns(uint256 stockTokenBalance){
        return stockToken.balanceOf(address(this));
    }
    
    function stockTokenCashValuation() internal view returns(uint256){
        uint256 cashEquivalent=(contractStockTokenBalance().mul(stockToCashRate)).div(stockTokenMultiplier);
        return cashEquivalent;
    }
    
    function contractCashValuation() public view returns(uint256 cashValauation){
        uint256 cashEquivalent=(contractStockTokenBalance().mul(stockToCashRate)).div(stockTokenMultiplier);
        return contractCashBalance().add(cashEquivalent);
    }

    function updatePoolRate() public returns (uint256 poolrate) {
        if(totalSupply()==0){
          poolToCashRate = (10**(cashDecimals)).mul(1);
        }
        else {
            poolToCashRate=( (contractCashValuation().mul(1e18)).div(totalSupply()) );
        }
        emit PoolRateUpdated(poolrate);
        return poolToCashRate;
    }
    
    function mintPoolToken(uint256 inputCashAmount) external {    
        if(cashValauationCap!=0)
        {
            require(inputCashAmount.add(contractCashValuation())<=cashValauationCap,"inputCashAmount exceeds cashValauationCap");
        }
        address sender= msg.sender;
        _preValidateData(sender,inputCashAmount);
        updatePoolRate();
        uint256 balanceBeforeTransfer = cash.balanceOf(address(this));
        cash.transferFrom(sender,address(this),inputCashAmount);
        uint256 balanceAfterTransfer = cash.balanceOf(address(this));
        require(balanceAfterTransfer == balanceBeforeTransfer.add(inputCashAmount),"Sent & Received Amount mismatched");
        // calculate pool token amount to be minted
        uint256 poolTokens = ( (inputCashAmount.mul(1e18)).div(poolToCashRate) );
        _mint(sender, poolTokens); //Minting  Pool Token
        emit PoolTokensMinted(sender,inputCashAmount,poolTokens);
    }
    
    function burnPoolToken(uint256 poolTokenAmount) external {  
        address sender= msg.sender;
        _preValidateData(sender,poolTokenAmount);
        
        updatePoolRate();
        uint256 cashToRedeem=( (poolTokenAmount.mul(poolToCashRate)).div(1e18) );
        _burn(sender, poolTokenAmount);
        
        uint256 outputStockToken = 0;
        uint256 outputCashAmount = 0;
        
        if( stockTokenCashValuation()>=cashToRedeem )
        {
         outputStockToken=( (cashToRedeem.mul(stockTokenMultiplier)).div(stockToCashRate) );//calculate stock token amount to be return
         stockToken.transfer(sender,outputStockToken);
        }
        
        else if( cashToRedeem>stockTokenCashValuation() )
        {
        outputStockToken=contractStockTokenBalance();
        outputCashAmount=cashToRedeem.sub(stockTokenCashValuation());// calculate cash amount to be return
        stockToken.transfer(sender,outputStockToken);
        
        uint256 balanceBeforeTransfer = cash.balanceOf(sender);
        cash.transfer(sender,outputCashAmount);
        uint256 balanceAfterTransfer = cash.balanceOf(sender);
        require(balanceAfterTransfer == balanceBeforeTransfer.add(outputCashAmount),"Sent & Received Amount mismatched");
        }
        emit PoolTokensBurnt(sender,poolTokenAmount,outputStockToken,outputCashAmount);
    }
    
    function redeemStockToken(uint256 stockTokenAmount) external{
        address sender= msg.sender;
        _preValidateData(sender,stockTokenAmount);
        stockToken.transferFrom(sender,address(this),stockTokenAmount);
        
        // calculate Cash amount to be return
        uint256 outputCashAmount=(stockTokenAmount.mul(stockToCashRate)).div(stockTokenMultiplier);
        uint256 balanceBeforeTransfer = cash.balanceOf(sender);
        cash.transfer(sender,outputCashAmount);
        uint256 balanceAfterTransfer = cash.balanceOf(sender);
        require(balanceAfterTransfer == balanceBeforeTransfer.add(outputCashAmount),"Sent & Received Amount mismatched");
        emit StockTokensRedeemed(sender,stockTokenAmount,outputCashAmount);
    }
    
    function kill() external onlyOwner {    //self destruct the code and transfer all contract balance to owner
        selfdestruct(owner);
    }
    
}