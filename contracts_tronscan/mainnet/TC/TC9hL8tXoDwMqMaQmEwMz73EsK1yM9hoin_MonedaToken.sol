//SourceUnit: Context.sol

// SPDX-License-Identifier: None
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

//SourceUnit: MonedaToken.sol

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;


import "./TRC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";

contract MonedaToken is TRC20 , Context , Ownable{
    using SafeMath for uint256;
 
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    address private _ownerAddress;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    
    mapping (address => bool) private  liquidityWallet;
    address private rewardWallet;
    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;
    
    mapping(address => uint256) private _firstbuy;
    mapping(address => uint256) private _totbuy;
    
    mapping(address => bool) private _isBadActor;
  
    mapping (address => bool) private _isExcludedFromFee;
    
    
    
    uint256 public maxSellAmountPerDay ;
    uint256 public maxSellAmountPerTxn ;
    
    uint256 public maxBuyAmountPerDay;
    uint256 public maxBuyAmountPerTxn ;
    
    uint256 private maxBurnAmount;
 
    constructor() {
        _name = "Moneda Coin";
        _symbol = "MCAM";
        _decimals = 9;
        _mint(msg.sender, 6000000 * 10**_decimals);
        _ownerAddress = msg.sender;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        rewardWallet=msg.sender;
        maxSellAmountPerDay = 500 * 10**_decimals;
        maxSellAmountPerTxn = 500 * 10**_decimals;    
        maxBuyAmountPerDay = 5000 * 10**_decimals;
        maxBuyAmountPerTxn = 500 * 10**_decimals;    
        maxBurnAmount = 3000000 * 10**_decimals;
    }
 
    function totalSupply() public view override returns (uint256 balance){
          return _totalSupply;
    } 
     
    function balanceOf(address account) public view override returns (uint256 balance){
          return _balances[account];
    }
 
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
 

    function transfer(address recipient, uint256 amount)  public override returns (bool success) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount)  public override returns  (bool success) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom( address sender, address recipient,  uint256 amount) public override returns  (bool success) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(), _allowances[sender][_msgSender()].sub( amount,"TRC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool)
    {
        _approve(_msgSender(),spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        _approve( _msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,"TRC20: decreased allowance below zero") );
        return true;
    }

    function _transfer( address sender,address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");
        require(!_isBadActor[sender] && !_isBadActor[recipient], "Bots are not allowed");
        
        
        bool isBuy =false;
        bool isSell =false;
        uint256 transferAmount=amount;
        uint256 rewardAmount=0;
        
        if (liquidityWallet[sender] && !_isExcludedFromFee[recipient])
        {
           require(amount <= maxBuyAmountPerTxn, "You can't buy more than maxbuy per transaction");
           if(block.timestamp < _firstbuy[recipient]+24 * 1 hours){
                require(_totbuy[recipient]+amount <= maxBuyAmountPerDay, "You can't buy more than maxBuyPerDay");
                _totbuy[recipient] = _totbuy[recipient].add(amount);
            }
            else{
                 require(amount <= maxBuyAmountPerDay, "You can't buy more than maxBuyPerDay");
                _firstbuy[recipient] = block.timestamp;
                _totbuy[recipient] = amount;
            }
            isBuy = true; 
        }
        
        if (liquidityWallet[recipient] && !_isExcludedFromFee[sender])
        {
            require(amount <= maxSellAmountPerTxn, "You can't sell more than maxSell per transaction");
            if(block.timestamp < _firstSell[sender]+24 * 1 hours){
                require(_totSells[sender]+amount <= maxSellAmountPerDay, "You can't sell more than maxSellPerDay");
               _totSells[sender]=_totSells[sender].add(amount);
            }
            else{
                require(amount <= maxSellAmountPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[sender] = block.timestamp;
                _totSells[sender] = amount;
            }
            isSell = true;
        }
        
        if(isBuy)
        {
           transferAmount =amount*98/100;
           rewardAmount = amount*2/100;
           
           _burn(_ownerAddress,amount*25/1000, true);
          
           _balances[sender] = _balances[sender].sub(amount,"TRC20: transfer amount exceeds balance" );
           _balances[recipient] = _balances[recipient].add(transferAmount);
           _balances[rewardWallet] = _balances[rewardWallet].add(rewardAmount);
          
           emit Transfer(sender, recipient, transferAmount);
           emit Transfer(sender, rewardWallet, rewardAmount); 
        }else if(isSell)
        {
           rewardAmount = amount*2/100;
           uint256 sellamount =amount.add(rewardAmount);
           
           _burn(_ownerAddress,amount*25/1000, true);
           
           _balances[sender] = _balances[sender].sub(sellamount,"TRC20: transfer amount exceeds balance" );
           _balances[recipient] = _balances[recipient].add(transferAmount);
           emit Transfer(sender, recipient, transferAmount);
           emit Transfer(sender, rewardWallet, rewardAmount);  
           
        }else
        {
            if (_isExcludedFromFee[recipient] || _isExcludedFromFee[sender])
            {
                _balances[sender] = _balances[sender].sub(transferAmount,"TRC20: transfer amount exceeds balance" );
                _balances[recipient] = _balances[recipient].add(transferAmount);
                emit Transfer(sender, recipient, transferAmount); 
            }
            else
            {
               transferAmount =amount*98/100;
               rewardAmount = amount*2/100;
               
               _burn(_ownerAddress,amount*25/1000, true);
               
               _balances[sender] = _balances[sender].sub(amount,"TRC20: transfer amount exceeds balance" );
               _balances[recipient] = _balances[recipient].add(transferAmount);
               _balances[rewardWallet] = _balances[rewardWallet].add(rewardAmount);
               
               emit Transfer(sender, recipient, transferAmount);
               emit Transfer(sender, rewardWallet, rewardAmount);
            }
        }
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount, bool isTrrxnburn) internal {
        require(account != address(0), "TRC20: burn from the zero address");
        
        if (isTrrxnburn)
        {
            if (maxBurnAmount>amount)
            {
                maxBurnAmount=maxBurnAmount.sub(amount, "TRC20: burn amount exceeds balance");
                _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
                _totalSupply = _totalSupply.sub(amount);
                emit Transfer(account, address(0), amount);
            }
        }else
        {
            _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, address(0), amount);
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount, false);
        _approve( account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
    
    
      function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellAmountPerDay = amount * 10**_decimals;
    } 
   
    function setmaxSellAmountPerTxn(uint256 amount) external onlyOwner{
        maxSellAmountPerTxn = amount * 10**_decimals;
    } 
    
    function setMaxBuyAmountPerDay(uint256 amount) external onlyOwner{
        maxBuyAmountPerDay = amount * 10**_decimals;
    } 
    
    function setMaxBuyAmountPerTxn(uint256 amount) external onlyOwner{
        maxBuyAmountPerTxn = amount * 10**_decimals;
    } 
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
   // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool isBadActor) external onlyOwner returns (bool success){
        _isBadActor[account] = isBadActor;
        return true;
    }
    
    function checkBadActor(address account) public view returns(bool){
        return _isBadActor[account];
    }
    
    function setLiquidityWallet(address payable _address) external onlyOwner returns (bool success){
        if (!liquidityWallet[_address])
        {
               liquidityWallet[_address] = true;
        }
        _isExcludedFromFee[_address] = true;
        return true;
    }
    
    
    function removeLiquidityWallet(address payable _address) external onlyOwner returns (bool success){
        if (liquidityWallet[_address])
        {
            liquidityWallet[_address] = false;
            _isExcludedFromFee[_address] = false;
        }
        return true;
    }
    
    
    function isLiquidityWalletAddress(address  _address) external view onlyOwner returns (bool success){
        return liquidityWallet[_address];
    }
    
    
    function setRewardWallet(address payable _address) external onlyOwner returns (bool success){
        rewardWallet = _address;
        _isExcludedFromFee[rewardWallet] = true;
        return true;
    }
    
    function getRewardWalletAddress() external view onlyOwner  returns (address _address){
        return rewardWallet;
    }
}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: None
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

abstract contract Ownable  {
    address private _owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _setOwner(msg.sender);
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

//SourceUnit: SafeMath.sol

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
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: TRC20.sol

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface TRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner,address indexed spender, uint256 value);
}