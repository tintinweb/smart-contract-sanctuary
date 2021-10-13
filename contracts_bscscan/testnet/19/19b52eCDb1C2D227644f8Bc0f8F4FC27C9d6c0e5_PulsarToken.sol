/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


interface ILP {
    function sync() external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IUniswapV2Router02 /*is IUniswapV2Router01*/ {

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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }


  //Locks the contract for owner
  function lock() public onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    emit OwnershipRenounced(_owner);

  }

  function unlock() public {
    require(_previousOwner == msg.sender, "You don’t have permission to unlock");
    require(now > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}


contract PulsarToken is ERC20Detailed, Ownable {
    using SafeMath for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event SwapEnabled(bool enabled);

    event SwapAndLiquify(
        uint256 threequarters,
        uint256 sharedETH,
        uint256 onequarter
    );


    // Used for authentication
    address public master;

    // LP atomic sync
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }


    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 21 * 10**6 * 10**DECIMALS;

    uint256 public transactionTax = 120;
  
    uint256 public numTokensSellDivisor = 10000;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;
    address public uniswapV2PairAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public marketingAddress;

    bool pauseTax = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    // bool public buyBackEnabled = false;

    mapping (address => bool) public _isExcluded;

    bool private privateSaleDropCompleted = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    constructor (address router, address payable _marketingAddress)
        ERC20Detailed("PulsarToken", "$Pulsar", uint8(DECIMALS))
        payable
        public
    {
        marketingAddress = _marketingAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        uniswapV2PairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        setLP(uniswapV2PairAddress);

        IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddress);

        uniswapV2Pair = _uniswapV2Pair;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);


        //exclude owner and this contract from fee
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }


    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
        external
        onlyOwner
        returns (uint256)
    {
        master = _master;
    }

        /**
     * @notice Sets contract LP address
     */
    function setLP(address _lp)
        public
        onlyOwner
        returns (uint256)
    {
        lpContract = ILP(_lp);
    }
    
    function excludeAddress(address _account) external onlyOwner returns(bool) {
        _isExcluded[_account] = true;
        return true;
    }
    
    function includeAddress(address _account) external onlyOwner returns(bool){
        _isExcluded[_account] = false;
        return true;
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }
    
    function setTaxPause(bool _pause) external onlyOwner {
        pauseTax = _pause;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address recipient, uint256 amount)
    external
    validRecipient(recipient)
    returns (bool)
    {
      _transfer(msg.sender, recipient, amount);
      return true;
    }

  event Sender(address sender);

   function transferFrom(address sender, address recipient, uint256 amount)
   external
   validRecipient(recipient)
   returns (bool)
   {
     _transfer(sender, recipient, amount);
     _approve(sender, msg.sender, _allowedFragments[sender][msg.sender].sub(amount));
     return true;
   }


    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function _transfer(address from, address to, uint256 value)
        private
        validRecipient(to)
        returns (bool)
    {
      require(from != address(0));
      require(to != address(0));
      require(value > 0);


        uint256 contractTokenBalance = balanceOf(address(this));
      uint256 numTokensSell = _totalSupply.div(numTokensSellDivisor);

      bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;

      if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2PairAddress) {
        if (overMinimumTokenBalance) {
            swapAndLiquify(numTokensSell);
        }

    }

        _tokenTransfer(from,to,value);

        return true;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

    if (_isExcluded[sender] || _isExcluded[recipient] || pauseTax) {
        _transferExcluded(sender, recipient, amount);
    } else {
        _transferStandard(sender, recipient, amount);
    }
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
      (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
          uint256 gonDeduct = amount.mul(_gonsPerFragment);
          uint256 gonValue = tTransferAmount.mul(_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender].sub(gonDeduct);
          _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
          _takeFee(tFee);
          emit Transfer(sender, recipient, amount);
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) private {
          uint256 gonValue = amount.mul(_gonsPerFragment);
          _gonBalances[sender] = _gonBalances[sender].sub(gonValue);
          _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);
          emit Transfer(sender, recipient, amount);
    }


    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }


    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(transactionTax).div(1000);
    }

    function _takeFee(uint256 tFee) private {
        uint256 rFee = tFee.mul(_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(rFee);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into quarters
        uint256 eleventwelfths = contractTokenBalance.mul(11).div(12);
        uint256 onetwelfths = contractTokenBalance.sub(eleventwelfths);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(eleventwelfths); 

        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 sharedETH = newBalance.div(11);
        uint256 marketingETH = newBalance.sub(sharedETH);

        // add liquidity to uniswap
        addLiquidity(onetwelfths, sharedETH);

        // Transfer to marketing address
        transferToAddressETH(marketingAddress, marketingETH);

        emit SwapAndLiquify(eleventwelfths, sharedETH, onetwelfths);

    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
    }

    function() external payable {}

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH.value(ethAmount)(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp.add(300)
        );
    }


     /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */

    function increaseAllowance(address spender, uint256 addedValue)
       public
       returns (bool)
   {
     _approve(msg.sender, spender, _allowedFragments[msg.sender][spender].add(addedValue));
       return true;
   }


  function _approve(address owner, address spender, uint256 value) private {
     require(owner != address(0));
     require(spender != address(0));

     _allowedFragments[owner][spender] = value;
     emit Approval(owner, spender, value);
 }

     /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of
    * msg.sender. This method is included for ERC20 compatibility.
    * increaseAllowance and decreaseAllowance should be used instead.
    * Changing an allowance with this method brings the risk that someone may transfer both
    * the old and the new allowance - if they are both greater than zero - if a transfer
    * transaction is mined before the later approve() call is mined.
    *
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */

    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
      _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }


    function burnAutoLP()
        external
        onlyOwner
    {
      uint256 balance = uniswapV2Pair.balanceOf(address(this));
      uniswapV2Pair.transfer(owner(), balance);
    }

    function airDrop(address[] calldata recipients, uint256[] calldata values)
        external
        onlyOwner
    {
      for (uint256 i = 0; i < recipients.length; i++) {
        _tokenTransfer(msg.sender, recipients[i], values[i]);
      }
    }


  function setnumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
  numTokensSellDivisor = _numTokensSellDivisor;}

  function burnBNB(address payable burnAddress) external onlyOwner {
    burnAddress.transfer(address(this).balance);
  }

}