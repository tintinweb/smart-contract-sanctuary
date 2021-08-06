/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

 
interface FarmTokens {
    
    function mint(address to, uint256 amount) external  ;
 
    function burnFrom(address account , uint256 amount) external ;
     
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface Token {
 
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);
}
 
interface FarmLandNFT {
 
    function tokenMoreDatas(uint256) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
 
}

 


contract MarketPlace is Ownable {
    using SafeMath for uint256;
     
 
 
    // The chicken token
    FarmTokens public chickenToken;
    // The egg token
    FarmTokens public eggToken;
    // The food token
    FarmTokens public chickenFoodToken;
    // The boar token
    FarmTokens public boarToken;
    // The sow token
    FarmTokens public sowToken;
    // The piglet token
    FarmTokens public pigletToken;
    // The pig food token
    FarmTokens public pigFoodToken;
    
    // Base Token
    Token public baseToken;

    // Farm Land NFT.
    FarmLandNFT public farmLand ;

    // Eggs per token.
    uint256 public eggsPerToken  = 0;

    // Chicken Food per token.
    uint256 public chickenFoodPerToken  = 0;
    uint256 public chickenGrams = 600;

    // Chicken per token.
    uint256 public chickenPerToken  = 0;

    // Boar per token.
    uint256 public boarPerToken  = 0;

    // Sow per token.
    uint256 public sowPerToken  = 0;

    // Piglet per token.
    uint256 public pigletPerToken  = 0;

    // Pig Food per token.
    uint256 public pigfoodPerToken  = 0;

    // Farm Land Area per token.
    uint256 public farmAreaPerToken  = 0;

    // Keep track of number of chickens sold 
    uint256 public totalChickenSold = 0;
    uint256 public totalChickenSoldValue = 0;

    // Keep track of number of eggs sold 
    uint256 public totalEggSold = 0;
    uint256 public totalEggSoldValue = 0;

    // Keep track of number of chicken food sold 
    uint256 public totalChickenFoodSold = 0;
    uint256 public totalChickenFoodSoldValue = 0;

    // Keep track of number of boar sold 
    uint256 public totalBoarSold = 0;
    uint256 public totalBoarSoldValue = 0;

    // Keep track of number of sow sold 
    uint256 public totalSowSold = 0;
    uint256 public totalSowSoldValue = 0;

    // Keep track of number of piglet sold 
    uint256 public totalPigletSold = 0;
    uint256 public totalPigletSoldValue = 0;

    // Keep track of number of pig food sold 
    uint256 public totalPigFoodSold = 0;
    uint256 public totalPigFoodSoldValue = 0;

    // Keep track of number of farm land sold 
    uint256 public totalFarmSold = 0;
    uint256 public totalFarmSoldValue = 0;
    
    // Keep track of number of chickens bought 
    uint256 public totalChickenBuy = 0;
    uint256 public totalChickenBuyValue = 0;

    // Keep track of number of eggs bought 
    uint256 public totalEggBuy = 0;
    uint256 public totalEggBuyValue = 0;

    // Keep track of number of chicken food bought 
    uint256 public totalChickenFoodBuy = 0;
    uint256 public totalChickenFoodBuyValue = 0;

    // Keep track of number of boar bought 
    uint256 public totalBoarBuy = 0;
    uint256 public totalBoarBuyValue = 0;

    // Keep track of number of sow bought 
    uint256 public totalSowBuy = 0;
    uint256 public totalSowBuyValue = 0;

    // Keep track of number of piglet bought 
    uint256 public totalPigletBuy = 0;
    uint256 public totalPigletBuyValue = 0;

    // Keep track of number of pig food bought 
    uint256 public totalPigFoodBuy = 0;
    uint256 public totalPigFoodBuyValue = 0;

    // Keep track of number of farm land bought 
    uint256 public totalFarmBuy = 0;
    uint256 public totalFarmBuyValue = 0;

    // Fees
    address public feeTaker = 0x36b219Fe9218DD0e94B2D67dF7562e2fCACcF445;
    uint256 public sellFee = 15;
 
    event Sale(address indexed user, uint256 amount);
    event Purchase(address indexed user,uint256 amount);
    event Claim(address indexed user, uint256 amount);
   

     constructor (
        FarmTokens _chickenToken,
        FarmTokens _eggToken,
        FarmTokens _chickenFoodToken,
        FarmTokens _boarToken,
        FarmTokens _sowToken,
        FarmTokens _pigletToken,
        FarmTokens _pigFoodToken,
        Token _baseToken,
        FarmLandNFT _farmLand
         
    )  {
        farmLand = _farmLand;
     
        chickenToken = _chickenToken;
        eggToken = _eggToken;
        chickenFoodToken = _chickenFoodToken;        
        boarToken = _boarToken;        
        sowToken = _sowToken;        
        pigletToken = _pigletToken;        
        pigFoodToken = _pigFoodToken;        
         
        baseToken = _baseToken;
 
    }




    // Get sell fee 
    function sellfee(uint256 _amount) public view returns (uint256) {
            uint256 _fee = _amount.mul(sellFee).div(1e3);            
            return _fee;
    }
    // Get Farm Land rate given area.
    function checkFarmLandPrice(uint256 _tokenId) public view returns (uint256) {
            uint256 _area = farmLand.tokenMoreDatas(_tokenId);
            uint256 _reqToken =  _area.div(farmAreaPerToken);
            return _reqToken;
    }

    // Buy Farm Land 
    function buyFarmLand(uint256 _tokenId) public  {
            uint256 _area = farmLand.tokenMoreDatas(_tokenId);
            uint256 _reqToken =  _area.div(farmAreaPerToken);
            baseToken.transferFrom(msg.sender,address(this),_reqToken);
            farmLand.transferFrom(address(this),msg.sender,_tokenId) ;      
            totalFarmSold = totalFarmSold.add(1)       ;
            totalFarmSoldValue = totalFarmSoldValue.add(_reqToken)   ;    
    }

    // Sell Farm Land 
    function sellFarmLand(uint256 _tokenId) public  {
            uint256 _area = farmLand.tokenMoreDatas(_tokenId);
            uint256 _reqToken =  _area.div(farmAreaPerToken);
            _reqToken = _reqToken.sub(sellfee(_reqToken)); 
            baseToken.transferFrom(address(this),msg.sender,_reqToken);
            farmLand.transferFrom(msg.sender,address(this),_tokenId)    ;    
            totalFarmBuy = totalFarmBuy.add(1)       ;
            totalFarmBuyValue = totalFarmBuyValue.add(_reqToken)   ;         
    }

    // Buy Farm Tokens 
    function buyfarmTokens(FarmTokens _farmtoken , uint256 _quantity) public {
                require(_quantity > 0, "Required Quantity must be zero");

                if(_farmtoken == chickenToken){
                    _transferChicken(_quantity,msg.sender);
                } 
                else if(_farmtoken == eggToken){
                    _transferEggs(_quantity,msg.sender);
                } 
                else if(_farmtoken == chickenFoodToken){
                    _transferChickenFood(_quantity,msg.sender);
                } 
                else if(_farmtoken == boarToken){
                    _transferBoar(_quantity,msg.sender);
                } 
                else if(_farmtoken == sowToken){
                    _transferSow(_quantity,msg.sender);
                } 
                else if(_farmtoken == pigletToken){
                    _transferPiglet(_quantity,msg.sender);
                } 
                else if(_farmtoken == pigFoodToken){
                    _transferPigFood(_quantity,msg.sender);
                } 
    }

    function sellFarmTokens(FarmTokens _farmtoken , uint256 _quantity) public {
                require(_quantity > 0, "Required Quantity must be zero");

                if(_farmtoken == chickenToken){
                    _burnChicken(_quantity,msg.sender);
                } 
                else if(_farmtoken == eggToken){
                    _burnEgg(_quantity,msg.sender);
                } 
                else if(_farmtoken == chickenFoodToken){
                    _burnChickenFood(_quantity,msg.sender);
                } 
                else if(_farmtoken == boarToken){
                    _burnBoar(_quantity,msg.sender);
                } 
                else if(_farmtoken == sowToken){
                    _burnSow(_quantity,msg.sender);
                } 
                else if(_farmtoken == pigletToken){
                    _burnPiglet(_quantity,msg.sender);
                } 
                else if(_farmtoken == pigFoodToken){
                    _burnPigFood(_quantity,msg.sender);
                } 

    }
    

 
  
    // Transfer Eggs 
    function _transferEggs(uint256 _quantity, address _user ) internal {
            if(_quantity > eggToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(eggToken.balanceOf(address(this))) ;                             
                 eggToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(eggsPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            eggToken.transfer(_user, _quantity); 
            totalEggSold = totalEggSold.add(_quantity) ;
            totalEggSoldValue = totalEggSoldValue.add(_cost)   ;    

    }

    // Transfer Chicken 
    function _transferChicken(uint256 _quantity, address _user ) internal {
            if(_quantity > chickenToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(chickenToken.balanceOf(address(this))) ;                             
                 chickenToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(chickenPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            chickenToken.transfer(_user, _quantity); 
            totalChickenSold = totalChickenSold.add(_quantity) ;
            totalChickenSoldValue = totalChickenSoldValue.add(_cost)   ;    


    }


    // Transfer Chicken Food
    function _transferChickenFood(uint256 _quantity, address _user ) internal {
            if(_quantity > chickenFoodToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(chickenFoodToken.balanceOf(address(this))) ;                             
                 chickenFoodToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(chickenFoodPerToken).div(chickenGrams);
            baseToken.transferFrom(_user,address(this),_cost);
            chickenFoodToken.transfer(_user, _quantity); 
            totalChickenFoodSold = totalChickenFoodSold.add(_quantity) ;
            totalChickenFoodSoldValue = totalChickenFoodSoldValue.add(_cost)   ;    

    }



    // Transfer Boar 
    function _transferBoar(uint256 _quantity, address _user ) internal {
            if(_quantity > boarToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(boarToken.balanceOf(address(this))) ;                             
                 boarToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(boarPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            boarToken.transfer(_user, _quantity); 
            totalBoarSold = totalBoarSold.add(_quantity) ;
            totalBoarSoldValue = totalBoarSoldValue.add(_cost)   ;    

    }


    // Transfer Sow 
    function _transferSow(uint256 _quantity, address _user ) internal {
            if(_quantity > sowToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(sowToken.balanceOf(address(this))) ;                             
                 sowToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(sowPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            sowToken.transfer(_user, _quantity); 
            totalSowSold = totalSowSold.add(_quantity) ;
            totalSowSoldValue = totalSowSoldValue.add(_cost)   ;    

    }


    // Transfer Piglet 
    function _transferPiglet(uint256 _quantity, address _user ) internal {
            if(_quantity > pigletToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(pigletToken.balanceOf(address(this))) ;                             
                 pigletToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(pigletPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            pigletToken.transfer(_user, _quantity); 
            totalPigletSold = totalPigletSold.add(_quantity) ;
            totalPigletSoldValue = totalPigletSoldValue.add(_cost)   ;    

    }


    // Transfer Pig Food 
    function _transferPigFood(uint256 _quantity, address _user ) internal {
            if(_quantity > pigFoodToken.balanceOf(address(this))){
                 uint256 _difference = _quantity.sub(pigFoodToken.balanceOf(address(this))) ;                             
                 pigFoodToken.mint(address(this), _difference);
            }
            uint256 _cost = _quantity.mul(pigfoodPerToken);
            baseToken.transferFrom(_user,address(this),_cost);
            pigFoodToken.transfer(_user, _quantity); 
            totalPigFoodSold = totalPigFoodSold.add(_quantity) ;
            totalPigFoodSoldValue = totalPigFoodSoldValue.add(_cost)   ;    

    }


   
    // Burn Chicken 
    function _burnChicken(uint _quantity , address _user) internal {    
            uint256 _cost = _quantity.mul(chickenPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);
            chickenToken.burnFrom(_user,_quantity);    
            totalChickenBuy = totalChickenBuy.add(_quantity)       ;
            totalChickenBuyValue = totalChickenBuyValue.add(_cost)   ;                                    
    }

    // Burn Chicken Egg 
    function _burnEgg(uint _quantity , address _user) internal {     
            uint256 _cost = _quantity.mul(eggsPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);     
            eggToken.burnFrom(_user,_quantity);     
            totalEggBuy = totalEggBuy.add(_quantity)       ;
            totalEggBuyValue = totalEggBuyValue.add(_cost)   ;                               
    }
    
    // Burn Chicken Food 
    function _burnChickenFood(uint _quantity , address _user) internal {  
            uint256 _cost = _quantity.mul(chickenFoodPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);        
            chickenFoodToken.burnFrom(_user,_quantity);            
            totalChickenFoodBuy = totalChickenFoodBuy.add(_quantity)       ;
            totalChickenFoodBuyValue = totalChickenFoodBuyValue.add(_cost)   ;                            
    }

    // Burn Piglet 
    function _burnPiglet(uint _quantity , address _user) internal {     
            uint256 _cost = _quantity.mul(pigletPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);     
            pigletToken.burnFrom(_user,_quantity);               
            totalPigletBuy = totalPigletBuy.add(_quantity)       ;
            totalPigletBuyValue = totalPigletBuyValue.add(_cost)   ;                         
    }

    // Burn Sow 
    function _burnSow(uint _quantity , address _user) internal {      
            uint256 _cost = _quantity.mul(sowPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);    
            sowToken.burnFrom(_user,_quantity);            
            totalSowBuy = totalSowBuy.add(_quantity)       ;
            totalSowBuyValue = totalSowBuyValue.add(_cost)   ;                            
    }

    // Burn Boar 
    function _burnBoar(uint _quantity , address _user) internal {        
            uint256 _cost = _quantity.mul(boarPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);  
            boarToken.burnFrom(_user,_quantity);             
            totalBoarBuy = totalBoarBuy.add(_quantity)       ;
            totalBoarBuyValue = totalBoarBuyValue.add(_cost)   ;                           
    }

    // Burn Pig Food 
    function _burnPigFood(uint _quantity , address _user) internal {    
            uint256 _cost = _quantity.mul(pigfoodPerToken);
            _cost = _cost.sub(sellfee(_cost)); 
            baseToken.transfer(_user,_cost);      
            pigFoodToken.burnFrom(_user,_quantity);          
            totalPigFoodBuy = totalPigFoodBuy.add(_quantity)       ;
            totalPigFoodBuyValue = totalPigFoodBuyValue.add(_cost)   ;                              
    }

   
    
 

   
    /* Admin Functions */


    /// @param _feeTaker address of feeTaker
    function setFeeTaker(address  _feeTaker)  external onlyOwner  {
       feeTaker = _feeTaker ;
    }

    /// @param _eggToken The amount of egg tokens to be given per day
    function setEggToken(FarmTokens _eggToken) external onlyOwner {
        eggToken = _eggToken;
    }

    /// @param  _chickenToken The chicken token
    function setChickenToken(FarmTokens _chickenToken) external onlyOwner {
        chickenToken = _chickenToken;
    }

    /// @param  _chickenFoodToken The chicken food token
    function setChickenFoodToken(FarmTokens _chickenFoodToken) external onlyOwner {
        chickenFoodToken = _chickenFoodToken;
    }

    /// @param  _boarToken The boar token
    function setBoarToken(FarmTokens _boarToken) external onlyOwner {
        boarToken = _boarToken;
    }

    /// @param  _sowToken The chicken food per day
    function setSowToken(FarmTokens _sowToken) external onlyOwner {
        sowToken = _sowToken;
    }

    /// @param  _pigletToken The chicken food per day
    function setPigletToken(FarmTokens _pigletToken) external onlyOwner {
        pigletToken = _pigletToken;
    }

    /// @param  _pigFoodToken The chicken food per day
    function setPigFoodToken(FarmTokens _pigFoodToken) external onlyOwner {
        pigFoodToken = _pigFoodToken;
    }


    /// @param  _farmLand The area per chicken
    function setFarmLand(FarmLandNFT _farmLand) external onlyOwner {
        farmLand = _farmLand;
    }

    
    /// @param  _baseToken The base token
    function setbaseToken(Token _baseToken) external onlyOwner {
            baseToken = _baseToken;
    }

    /// @param  _chickenPerToken chicken per token
    function setChickenPerToken(uint256 _chickenPerToken) external onlyOwner {
            chickenPerToken  = _chickenPerToken;

    }

    /// @param  _eggsPerToken chicken per token
    function setEggPerToken(uint256 _eggsPerToken) external onlyOwner {
            eggsPerToken = _eggsPerToken;

    }

    /// @param  _chickenFoodPerToken chicken food per token
    function setChickenFoodPerToken(uint256 _chickenFoodPerToken) external onlyOwner {
                 chickenFoodPerToken = _chickenFoodPerToken;            
    }


    /// @param  _chickenGrams chicken food grams per $1
    function setChickenFoodGramsPerUsd(uint256 _chickenGrams) external onlyOwner {
                 chickenGrams = _chickenGrams;            
    }



    /// @param  _boarPerToken boar per token
    function setBoarPerToken(uint256 _boarPerToken) external onlyOwner {
                   boarPerToken  = _boarPerToken;
    }

    /// @param  _sowPerToken sow per token
    function setSowPerToken(uint256 _sowPerToken) external onlyOwner {
                   sowPerToken = _sowPerToken ;
    }

    /// @param  _pigletPerToken piglet per token
    function setPigletPerToken(uint256 _pigletPerToken) external onlyOwner {
                   pigletPerToken = _pigletPerToken ;
    }

    /// @param  _pigfoodPerToken pig food per token
    function setPigFoodPerToken(uint256 _pigfoodPerToken) external onlyOwner {
                pigfoodPerToken = _pigfoodPerToken;
    }


    /// @param  _farmAreaPerToken area per token
    function setFarmLandRate(uint256 _farmAreaPerToken) external onlyOwner {
                farmAreaPerToken = _farmAreaPerToken;
    }
 
    /// @dev Obtain the chicken token balance
    function getTotalChicken() public view returns (uint256) {
          return chickenToken.balanceOf(address(this));
    }

    /// @dev Obtain the egg token balance
    function getTotalEgg() public view returns (uint256) {
          return eggToken.balanceOf(address(this));
    }

    /// @dev Obtain the chicken token balance
    function getTotalChickenFood() public view returns (uint256) {
          return chickenFoodToken.balanceOf(address(this));
    }

    /// @dev Obtain the boar token balance
    function getTotalBoar() public view returns (uint256) {
          return boarToken.balanceOf(address(this));
    }


    /// @dev Obtain the sow token balance
    function getTotalSow() public view returns (uint256) {
          return sowToken.balanceOf(address(this));
    }

    /// @dev Obtain the piglet token balance
    function getTotalPiglet() public view returns (uint256) {
          return pigletToken.balanceOf(address(this));
    }

    /// @dev Obtain the pig food token balance
    function getTotalPigFood() public view returns (uint256) {
          return pigFoodToken.balanceOf(address(this));
    }
 
    function transferAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {        
        Token(_tokenAddr).transfer(_to, _amount);
    }


     

}