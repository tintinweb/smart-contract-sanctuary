/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

 pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
     *
     * _Available since v2.4.0._
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
     * _Available since v2.4.0._
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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}






contract Governance {
    address public governance;

    constructor() public {
        governance = tx.origin;
    }

    event GovernanceTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyGovernance() {
        require(msg.sender == governance, "not governance");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(governance, _governance);
        governance = _governance;
    }
}



/// @title DegoToken Contract

contract Token is Governance, IERC20 {
    using SafeMath for uint256;

    //events
    event eveSetRate(uint256[2] fomo_rate, uint256[2] burn_rate , uint256[2] operate_rate , uint256[2] market_rate);
    event eveRewardPool(address fomoPool, address burnPool ,address operatePool ,address marketPool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // for minters
    mapping(address => bool) public _minters;
    mapping(address => uint256) public _minters_number;
    //token base data
    uint256 internal _totalSupply;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    /// Constant token specific fields
    uint8 internal constant _decimals = 18;
    uint256 public _maxSupply = 0;
    
    string private _name = "lucky100"; 
    string private _symbol = "lucky100"; 

    ///
    bool public _openTransfer = false;

    // hardcode limit rate
    uint256 public constant _maxGovernValueRate = 100; 
    uint256 public constant _minGovernValueRate = 0; 
    uint256 public constant _rateBase = 100;

    // additional variables for use if transaction fees ever became necessary
    uint256[2] public _burnRate = [2,2];
    uint256[2] public _fomoRate = [8,8];
    uint256[2] public _operateRate = [3,3];
    uint256[2] public _marketRate = [2,2];
    

    uint256 public _totalBurnToken = 0;
    uint256 public _totalFomoToken = 0;
    uint256 public _totalOperateToken = 0;
    uint256 public _totalMarketToken = 0;

    //todo reward pool!
    address public _fomoPool = 0x632341cfB580FcB096064fC1D0358557fe011014;
    //todo burn pool!
    address public _burnPool = 0x9B2A94dC6272586dCcF26E959b83bE86AF91Ffa0;

    address public _operatePool = 0x58Cb7122c636f330618De06f4c56b61BfB9818C6;

    address public _marketPool = 0xEC2F1858129e95F1E41b1683Aa772b9F6061adeA;

    address public uniswapV2Pair; 
    IUniswapV2Router02 public uniswapV2Router; 

    bool public buylimit = true;
    bool public selllimit = true;
    
    /**
     * @dev set the token transfer switch
     */
    function enableOpenTransfer() public onlyGovernance {
        _openTransfer = true;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Token
     */

    constructor() public {
        uint256 _exp = _decimals;
        
        _maxSupply = 15000000000 * (10**_exp);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(
            msg.sender != address(0),
            "ERC20: approve from the zero address"
        );
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
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


    /**
     * @dev Function to check the amount of tokens than an owner _allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev return the token total supply
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev for mint function
     */
    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_minters[msg.sender], "!minter");
        require(_minters_number[msg.sender] >= amount);
        uint256 curMintSupply = _totalSupply.add(_totalBurnToken);
        uint256 newMintSupply = curMintSupply.add(amount);
        require(newMintSupply <= _maxSupply, "supply is max!");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _minters_number[msg.sender] = _minters_number[msg.sender].sub(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }

    function addMinter(address _minter, uint256 number) public onlyGovernance {
        _minters[_minter] = true;
        _minters_number[_minter] = number;
    }

    function setMinter_number(address _minter, uint256 number)
        public
        onlyGovernance
    {
        require(_minters[_minter]);
        _minters_number[_minter] = number;
    }

    function removeMinter(address _minter) public onlyGovernance {
        _minters[_minter] = false;
        _minters_number[_minter] = 0;
    }



    /**
     * @dev for govern value
     */
    function setRate(uint256[2] memory fomoRate, uint256[2] memory burnRate , uint256[2] memory operateRate , uint256[2] memory marketRate)
        public
        onlyGovernance
    {

        for(uint i = 0;i<2;i++){
            require(
            _maxGovernValueRate >= fomoRate[i] &&
                fomoRate[i] >= _minGovernValueRate,
            "invalid fomo rate"
            );
        }
        for(uint i = 0;i<2;i++){
            require(
            _maxGovernValueRate >= burnRate[i] &&
                burnRate[i] >= _minGovernValueRate,
            "invalid burn rate"
            );
        }
        for(uint i = 0;i<2;i++){
            require(
            _maxGovernValueRate >= operateRate[i] &&
                operateRate[i] >= _minGovernValueRate,
            "invalid operate rate"
            );
        }
        for(uint i = 0;i<2;i++){
            require(
            _maxGovernValueRate >= marketRate[i] &&
                marketRate[i] >= _minGovernValueRate,
            "invalid market rate"
            );
        }
        
        _fomoRate = fomoRate;
        _burnRate = burnRate;
        _operateRate = operateRate;
        _marketRate = marketRate;

        emit eveSetRate(_fomoRate, _burnRate,_operateRate,_marketRate);
    }

    /**
     * @dev for set reward
     */
    function setRewardPool(address fomoPool, address burnPool , address operatePool ,address marketPool)
        public
        onlyGovernance
    {
        require(fomoPool != address(0x0));
        require(operatePool != address(0x0));
        require(marketPool != address(0x0));


        _fomoPool = fomoPool;
        _burnPool = burnPool;
        _operatePool = operatePool;
        _marketPool = marketPool;

        emit eveRewardPool(_fomoPool, _burnPool ,_operatePool,_marketPool);
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public  override returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        uint256 allow = _allowances[from][msg.sender];
        _allowances[from][msg.sender] = allow.sub(value);

        return _transfer(from, to, value);
    }

    /**
     * @dev Transfer tokens with fee
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256s the amount of tokens to be transferred
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // :)
        require(_openTransfer || from == governance, "transfer closed");

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 sendAmount = value;
        
        
        if (to == uniswapV2Pair) {
            
            if (selllimit) {
                uint reservesNum;
                if (address(this) == IUniswapV2Pair(uniswapV2Pair).token0()) {
                   (reservesNum,,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                }if (address(this) == IUniswapV2Pair(uniswapV2Pair).token1()) {
                   (,reservesNum,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                }
                if (value >= reservesNum.div(1000)) {
                    return false;
                }
                
            }
            
            uint256 fomoFee = (value.mul(_fomoRate[0])).div(_rateBase);
            if (fomoFee > 0) {
                //to burn
                _balances[_fomoPool] = _balances[_fomoPool].add(fomoFee);
                
                sendAmount = sendAmount.sub(fomoFee);

                _totalFomoToken = _totalFomoToken.add(fomoFee);

                emit Transfer(from, _fomoPool, fomoFee);
            }

            uint256 burnFee = (value.mul(_burnRate[0])).div(_rateBase);
            if (burnFee > 0) {
                //to reward
                _balances[_burnPool] = _balances[_burnPool].add(burnFee);
                //_totalSupply = _totalSupply.sub(burnFee);
                sendAmount = sendAmount.sub(burnFee);

                _totalBurnToken = _totalBurnToken.add(burnFee);

                emit Transfer(from, _burnPool, burnFee);
            }

            uint256 operateFee = (value.mul(_operateRate[0])).div(_rateBase);
            if (operateFee > 0) {
                //to reward
                _balances[_operatePool] = _balances[_operatePool].add(operateFee);
                sendAmount = sendAmount.sub(operateFee);

                _totalOperateToken = _totalOperateToken.add(operateFee);

                emit Transfer(from, _operatePool, operateFee);
            }

            uint256 marketFee = (value.mul(_marketRate[0])).div(_rateBase);
            if (marketFee > 0) {
                //to reward
                _balances[_marketPool] = _balances[_marketPool].add(marketFee);
                sendAmount = sendAmount.sub(marketFee);

                _totalMarketToken = _totalMarketToken.add(marketFee);

                emit Transfer(from, _marketPool, marketFee);
            }
        } else if (from == uniswapV2Pair) {
            if (buylimit) {
                uint reservesNum;
                if (address(this) == IUniswapV2Pair(uniswapV2Pair).token0()) {
                   (reservesNum,,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                }if (address(this) == IUniswapV2Pair(uniswapV2Pair).token1()) {
                   (,reservesNum,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                }
                if (value >= reservesNum.div(1000)) {
                    return false;
                }
                
            }
            
            uint256 fomoFee = (value.mul(_fomoRate[1])).div(_rateBase);
            if (fomoFee > 0) {
                //to burn
                _balances[_fomoPool] = _balances[_fomoPool].add(fomoFee);
                sendAmount = sendAmount.sub(fomoFee);

                _totalFomoToken = _totalFomoToken.add(fomoFee);

                emit Transfer(from, _fomoPool, fomoFee);
            }

            uint256 burnFee = (value.mul(_burnRate[1])).div(_rateBase);
            if (burnFee > 0) {
                //to reward
                _balances[_burnPool] = _balances[_burnPool].add(burnFee);
                sendAmount = sendAmount.sub(burnFee);
                _totalSupply = _totalSupply.sub(burnFee);
                _totalBurnToken = _totalBurnToken.add(burnFee);

                emit Transfer(from, _burnPool, burnFee);
            }

            uint256 operateFee = (value.mul(_operateRate[1])).div(_rateBase);
            if (operateFee > 0) {
                //to reward
                _balances[_operatePool] = _balances[_operatePool].add(operateFee);
                sendAmount = sendAmount.sub(operateFee);

                _totalOperateToken = _totalOperateToken.add(operateFee);

                emit Transfer(from, _operatePool, operateFee);
            }

            uint256 marketFee = (value.mul(_marketRate[1])).div(_rateBase);
            if (marketFee > 0) {
                //to reward
                _balances[_marketPool] = _balances[_marketPool].add(marketFee);
                sendAmount = sendAmount.sub(marketFee);

                _totalMarketToken = _totalMarketToken.add(marketFee);

                emit Transfer(from, _marketPool, marketFee);
            }
        }else {
            
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(sendAmount);

        emit Transfer(from, to, sendAmount);

        return true;
    }
    
    function setLimits(bool  _buylimit,bool  _selllimit)
        public
        onlyGovernance
    {
        buylimit=_buylimit;
        selllimit=_selllimit;
    }
    
}