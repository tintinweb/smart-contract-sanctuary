// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
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
    function _burn(address account, uint256 amount) internal {
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}





contract LimitOrders {
  using SafeMath for uint256;
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Router02 public uniswapRouter;
  mapping(string => Order) public orders;
  mapping(address => Order) public findOrderByWallet;
  uint timeVault = now;
  address owner;
  address newOwner;

  constructor() public {
    owner = msg.sender;
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }
  
 modifier onlyOwner(){
      require(msg.sender == owner, "permission failed");
      _;
 }
 
 event orderEvent (
     string indexed orderId,
     uint indexed targetPrice,
     uint indexed timeLimit,
     uint amount,
     address walletAddress
  );
  
  event orderCancelled (
     string indexed orderId,
     uint indexed timeLimit,
     address walletAddress,
     uint amount
  );
  
   event transEvent (
     address indexed tokenA,
     address tokenB
  );

 struct Order {
     string orderId;
     uint amount;
     uint amountWithFees;
     uint targetPrice;
     uint stopLossPrice;
     uint timeLimit;
     address walletAddress;
     address tokenAddress;
     string status;
     bool sellOrder;
     bool isCompleted;
     bool isValue;
 }
 
 struct OrdersList {
     string orderId;
     uint amount;
     uint amountOutMin;
     uint gasPrice;
     bool sellOrder;
 }


// CREATE A NEW ORDER
 function createOrder(
     string calldata _orderId,
     uint _amount, 
     uint _amountWithFees, 
     uint _targetPrice,
     uint _stopLossPrice,
     uint _timeLimit,
     address _tokenAddress,
     bool _sellOrder
     ) external payable returns (bool) {
     require(!orders[_orderId].isValue, "orderid should be unique");
     Order memory _order = Order(_orderId, _amount, _amountWithFees, _targetPrice,_stopLossPrice,_timeLimit,msg.sender,_tokenAddress,"pending",_sellOrder,false,true);
     orders[_orderId] = _order;
     findOrderByWallet[msg.sender] = _order;
     if(_sellOrder){
         require(_amount >= _amountWithFees, "invalid amount");
         transferFromUserAccount(_amount, _tokenAddress);
     }else {
         require(msg.value >= _amount, "invalid amount");
         address(this).transfer(_amount);
     }
     emit orderEvent(_orderId, _targetPrice, _timeLimit, _amount, msg.sender);
  }
  
  
  //EXECUTES ALL PENDING ORDERS 
  function executeOrders(string calldata _orderId, uint _amountOutMin, uint _allowedAmount, address payable _feesWallet) 
        external onlyOwner {
        require(!orders[_orderId].isCompleted, "order is already processed");
        Order memory _order = orders[_orderId];
            if(!_order.sellOrder){
               swapEthToToken(_order.timeLimit, _order.amount, _amountOutMin, _order.amountWithFees, _order.tokenAddress, _feesWallet);
               orders[_orderId].status = "success";
               orders[_orderId].isCompleted = true;
            }else {
               swapTokenToETH(_order.timeLimit, _order.amount, _amountOutMin, _order.tokenAddress, _allowedAmount, _order.amountWithFees, _feesWallet); 
               orders[_orderId].status = "success";
               orders[_orderId].isCompleted = true;
            }
            emit orderEvent(_orderId, _order.targetPrice, _order.timeLimit, _order.amount, _order.walletAddress);

  }
  
 
 //USER CANCEL OR RETRIVE AN ORDER
 function cancelOrder(string calldata _orderId, string calldata _status) external {
     require(orders[_orderId].isValue);
     Order memory _order = orders[_orderId];
     require(!_order.isCompleted && msg.sender == _order.walletAddress, "cancel condition not met");
     ERC20 token = ERC20(_order.tokenAddress);
     if(_order.sellOrder){
         token.transfer(_order.walletAddress, _order.amount);
         orders[_orderId].status = _status;
         orders[_orderId].isCompleted = true;
     }else{
         msg.sender.transfer(_order.amount);
         orders[_orderId].status = _status;
         orders[_orderId].isCompleted = true;
     }
     emit orderCancelled(_order.orderId, _order.timeLimit, _order.walletAddress, _order.amount);
 }
 
 
 //GET AN ORDER STATUS
 function getOrderStatus(string calldata _orderId) 
      external view returns(string memory){
      return orders[_orderId].status;
 }
 
 
 //UPDATE ORDER STATUS ON EXPIRATION OF IF FAIL TO FULLFILL
 function updateOrderStatus(string calldata _orderId, string calldata _status) 
      external onlyOwner returns(string memory){
      require(!orders[_orderId].isCompleted, "update condition not met");
      orders[_orderId].status = _status;
      orders[_orderId].isCompleted = true;
      return _status;
 }
 
 //...............................................................................
 
 function convertEthToToken(uint deadline, uint _amountIn, uint _amountOutMin, 
   uint _amountWithFees, address _tokenAddress, address payable _feesWallet) external payable 
    returns(uint[] memory) {
    require(msg.value >= _amountIn, "invalid amount");
    uint[] memory result = uniswapRouter.swapExactETHForTokens{value: _amountWithFees}(_amountOutMin, getPathForETHtoToken(_tokenAddress), msg.sender, deadline);
    uint fees = _amountIn.sub(_amountWithFees);
    transferToWallet(fees, _feesWallet);
    return result;
}

 
 function convertTokenToETH(uint deadline, uint _amountIn, uint _amountOutMin, 
    address _tokenAddress, uint _allowedAmount, uint _amountWithFees, address _feesWallet) external 
    returns(uint){
    require(_amountIn >= _amountWithFees , "invalid amount");
    ERC20 token = ERC20(_tokenAddress);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        transferFromUserAccount(_amountIn, _tokenAddress);
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddress);
    } else {
        transferFromUserAccount(_amountIn, _tokenAddress);
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddress);
    }
 }

 
 function convertTokenToEthSupportTokensWithFees(uint deadline, uint _amountIn, uint _amountOutMin,
 address _tokenAddress, uint _allowedAmount, uint _amountWithFees) public payable returns(bool) {
    require(_amountIn >= _amountWithFees , "invalid amount");
    ERC20 token = ERC20(_tokenAddress);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        transferFromUserAccount(_amountIn, _tokenAddress);
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    } else {
        transferFromUserAccount(_amountIn, _tokenAddress);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    }
}
 
  

 function getEstimatedETHforToken(uint _amount, address _tokenAddress) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(_amount, getPathForETHtoToken(_tokenAddress));
  }
 
  
function getPathForETHtoToken(address _tokenAddress) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _tokenAddress;
    return path;
  }
 
  
function swapEthToToken(uint deadline, uint _amountIn, uint _amountOutMin,
    uint _amountWithFees, address _tokenAddress, address payable _feesWallet) private returns(uint[] memory) {
    uint[] memory result = uniswapRouter.swapExactETHForTokens{value: _amountWithFees}(_amountOutMin, getPathForETHtoToken(_tokenAddress), msg.sender, deadline);
    uint fees = _amountIn.sub(_amountWithFees);
    transferToWallet(fees, _feesWallet);
    return result;
}


function swapTokenToETH(uint deadline, uint _amountIn, uint _amountOutMin, 
   address _tokenAddress, uint _allowedAmount, uint _amountWithFees, address _feesWallet) private 
    returns(uint){
    require(_amountIn >= _amountWithFees , "invalid amount");
    ERC20 token = ERC20(_tokenAddress);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddress);
    } else {
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddress);
    }
    
 }
 
 //........................................................................................
 
 function swap(uint deadline, uint _amountIn, uint _amountOutMin, 
    address _tokenAddressA, address _tokenAddressB, 
    uint _allowedAmount, uint _amountWithFees, address _feesWallet) external{
    require(_amountIn >= _amountWithFees , "invalid amount");
    ERC20 token = ERC20(_tokenAddressA);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        transferFromUserAccount(_amountIn, _tokenAddressA);
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForTokens(_amountWithFees, _amountOutMin, getPathForTokenToToken(_tokenAddressA,_tokenAddressB), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddressA);
    } else {
        transferFromUserAccount(_amountIn, _tokenAddressA);
        uniswapRouter.swapExactTokensForTokens(_amountWithFees, _amountOutMin, getPathForTokenToToken(_tokenAddressA,_tokenAddressB), msg.sender, deadline);
        uint fees = _amountIn.sub(_amountWithFees);
        transferToWalletTokens(fees, _feesWallet, _tokenAddressA);
    }
 }
 
 //.....................................................................................

 function getPathForTokenToToken(address _tokenAddressA, address _tokenAddressB) public view returns (address[] memory) {
    address[] memory path = new address[](3);
    path[0] = _tokenAddressA;
    path[1] = uniswapRouter.WETH();
    path[2] = _tokenAddressB;
    return path;
  }
  
 function getPathForTokenToETH(address _tokenAddress) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = _tokenAddress;
    path[1] = uniswapRouter.WETH();
    return path;
  }
 
 
 function getEstimatedTokenToETH(uint _amount, address _tokenAddress) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(_amount, getPathForTokenToETH(_tokenAddress));
 }



function transferFromUserAccount(uint _amountIn, address _tokenAddress) private returns(bool){
  ERC20 token = ERC20(_tokenAddress);
  token.transferFrom(msg.sender, address(this), _amountIn);
  return true;
  }
  
 function checkAllowance(address _spender, address _tokenAddress) external view returns(uint){
   ERC20 token = ERC20(_tokenAddress);
   uint allowed = token.allowance(msg.sender, _spender);
   return allowed;
 }
 
 function assignOwner(address _newOwner) external onlyOwner returns(address){
     newOwner = _newOwner;
     return newOwner;
 }
 
 function acceptOwnership() external returns(address){
     require(msg.sender == newOwner, "msg.sender should match newOwner");
     owner = newOwner;
     return owner;
 }
 
 function transferToWallet(uint _amount, address payable _receipient) 
      private returns(bool){
     _receipient.transfer(_amount);
      return true;
 }
 
  function transferToWalletTokens(uint _amount, address _receipient, address _tokenAddress) 
     private returns(bool){
     ERC20 token = ERC20(_tokenAddress);
     token.transfer(_receipient, _amount);
     return true;
     
 }
 
 
  receive() payable external {}
}