/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initialize() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface IUniswapV2Router {
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
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface cycleBurn {
    function _updateLPSupplyAndBurn() external;
    function updatelpSupply( uint112 _lpSupply) external;
    function updateStartBlock( uint _startTime) external;
    
}

interface IAirDrop{
    function transferFromIAirDrop( address _owner, address _IAirDrop, uint _amount) external returns (bool);
}

interface IRewardPool {
    function updatePool(uint _amount) external returns (bool);
    function updateHolderLiquidity( address _holder, uint8 _flag) external returns (bool);
}

contract DXB is IERC20, Context, Ownable, Initializable {
    using SafeMath for uint256;
    
    event Burn(address indexed burner, uint256 value);
    
    IUniswapV2Router public  uniswapV2Router;
    address public  uniswapV2Pair;
    address public CycleBurn;
 
    mapping(address => uint256) private _balances;
 
    mapping(address => mapping (address => uint256)) private _allowed;
    
    mapping(address => bool) public excludeFromFeeBNB;
    
    mapping(address => bool) public excludeFromDeduction;
    
    mapping (address => mapping(uint => bool)) public _rBNBReceived;
    
    address public IAirDropContract;
    address public teamWaultContract;
    address public rewardPool;
    
    address[] public _excludedWallets;
    
    address public _charityFeeWallet;
    address public _marketFeeWallet;
    address public _useCaseFeeWallet;
    
    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint public _taxFee;
    uint public _restoreTaxFee;
    uint public _addLPFee;
    uint public _restoreAddLPFee;
    uint public _liquidityFee;
    uint public _restoreLiquidityFee;
    uint public _burnFee;
    uint public _restoreBurnFee;
    
    uint public _charityFee;
    uint public _marketFee;
    uint public _useCaseFee;
    
    bool public reductionInTax;
    bool public isSwapEnable;
    bool public inSwapAndLiquify;
    bool public inSwapAndLiquifyLP;
    
    uint public _rInSupply;
    uint256 public _maxAmountPerTx;
    uint256 public lastAddLPTimestamp;
    uint256 public addLPDelay;
    
    function initialize (address _cycleBurn, address _teamVault, address _IAirDrop, address _IRewardPool, address[3] memory _feeWallet) external initializer {
        name = 'DXB';
        symbol = 'DXB';
        decimals = 18;
        
        CycleBurn = _cycleBurn;
        IAirDropContract = _IAirDrop;
        teamWaultContract = _teamVault;
        rewardPool = _IRewardPool;
        
        _initialize();
        
        _taxFee = 5;
        _addLPFee = 2;
        _liquidityFee = 50;
        _burnFee = 50;
        
        reductionInTax = true;
        isSwapEnable = false;
        
        _rInSupply = 10000000000000e18; // 10 trillion.
        _maxAmountPerTx = 5000000*10**18;
        
        lastAddLPTimestamp = block.timestamp;
        addLPDelay = 1 days;
        
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        mint(msg.sender,351750000000000e18);
        mint(_teamVault,23250000000000e18);
        mint(CycleBurn,125000000000000e18);
        
        _charityFee = 10;
        _marketFee = 10;
        _useCaseFee = 10;
        
        _charityFeeWallet = _feeWallet[0];
        _marketFeeWallet = _feeWallet[1];
        _useCaseFeeWallet = _feeWallet[2];   
        
        excludeFromDeduction[address(this)] = true;
        excludeFromDeduction[_teamVault] = true;
        excludeFromDeduction[_IAirDrop] = true;
    }
    
    modifier lockTheSwap { 
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    modifier lockTheSwapLP { 
        inSwapAndLiquifyLP = true;
        _;
        inSwapAndLiquifyLP = false;
    }
    
    receive() external payable {
    }
    
    /** 
     * @dev Calls totalSupply() function to view total supply.
     * @return uint256 total supply.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    /** 
     * @dev Calls balanceOf() function to view balance of owner.
     * @param owner owner address.
     * @return uint256 owner balance.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];   
    }
 
    /** 
     * @dev Calls allowance() function to view allowance of spender.
     * @param owner owner address.
     * @param spender spender address.
     * @return uint256 allowance.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }
 
    /** 
     * @dev Calls transfer() function to transfer tokens.
     * @param to receiver address.
     * @param value value to send.
     * @return bool true.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
 
    /** 
     * @dev Calls approve() function to approve tokens.
     * @param spender receiver address.
     * @param value value to send.
     * @return bool true.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        require(spender != address(0), "DXB :: approve : invalid spender");
        _approve(_msgSender(), spender, value);
        return true;
    }
 
    /** 
     * @dev Calls transferFrom() function to receive tokens from sender.
     * @param from sender address.
     * @param to receiver address.
     * @param value value to send.
     * @return bool true.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }
    
    /** 
     * @dev Calls IAirDropApproveAndCall() function to transfer tokens to Airdrop.
     * @param spender receiver address.
     * @param tokens value to send.
     * @return bool true.
     */
    function IAirDropApproveAndCall(address spender, uint256 tokens) external onlyOwner returns (bool) {
        require(IAirDropContract != address(0), "DXB :: IAirDropApproveAndCall : AirDrop contract is not set");
        _allowed[msg.sender][IAirDropContract] = tokens;
        emit Approval(msg.sender, IAirDropContract, tokens);
        IAirDrop(IAirDropContract).transferFromIAirDrop(owner(), spender, tokens);
        return true;
    }
    
    /** 
     * @dev Calls burn() function to burn tokens.
     * @param _value value to send.
     */
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);
    }
    
    /** 
     * @dev Calls excludeFrom() function to exclude wallet from fee.
     * @param _wallet exclude wallet address.
     */
    function excludeFrom( address _wallet) external onlyOwner {
        require(!excludeFromFeeBNB[_wallet], "DXB :: excludeFrom : already excluded");
        excludeFromFeeBNB[_wallet] = true;
        _excludedWallets.push(_wallet);
    }
    
    /** 
     * @dev Calls includeTo() function to include wallet from fee.
     * @param _wallet exclude wallet address.
     */
    function includeTo( address _wallet) external onlyOwner {
        require(excludeFromFeeBNB[_wallet], "DXB :: Already included in fee");
        for (uint256 i = 0; i < _excludedWallets.length; i++) {
            if (_excludedWallets[i] == _wallet) {
                _excludedWallets[i] = _excludedWallets[_excludedWallets.length - 1];
                excludeFromFeeBNB[_wallet] = false;
                _excludedWallets.pop();
                break;
            }
        }
    }
    
    function excludeFromHolderDeduction( address _wallet) external onlyOwner {
        require(!excludeFromDeduction[_wallet], "DXB :: excludeFrom deduction : already excluded");
        excludeFromDeduction[_wallet] = true;
    }
    
    function includeToHolderDeduction( address _wallet) external onlyOwner {
        require(excludeFromDeduction[_wallet], "DXB :: includeTo deduction : Already included in fee");
        excludeFromDeduction[_wallet] = false;
    }
    
    /** 
     * @dev Calls _updateCycleburn() function to update cycle burn address.
     * @param _cycleBurn cycle burn contract address.
     */
    function updateCycleburn( address _cycleBurn) external onlyOwner { CycleBurn = _cycleBurn; }
    
    function updateRewardPool( address _rewardPool) external onlyOwner { rewardPool = _rewardPool; }
    
    function updateIAirDropContract( address _IAirDropContract) external onlyOwner { IAirDropContract = _IAirDropContract; }
    
    function updateTeamWaultContract( address _teamWaultContract) external onlyOwner { teamWaultContract = _teamWaultContract; }
    
    function updateTaxFee( uint _tax) public onlyOwner { _taxFee = _tax; }
    
    function updateBurnAndLiquidityFee( uint _liqFee, uint _bFee) external onlyOwner {
        require((_liqFee+_bFee) <= 100, "should not exceed 100 percent");
        _liquidityFee = _liqFee;
        _burnFee = _bFee; 
    }
    
    function updateAddLiquidityFee( uint _lpFee) external onlyOwner { _addLPFee = _lpFee; }
    
    /** 
     * @dev Calls _updateCharityFee() function to update charity fee.
     * @param charityFee charity fee.
     */
    function updateCharityFee( uint charityFee) external onlyOwner { _charityFee = charityFee; }
    
    /** 
     * @dev Calls _updateMarketingFee() function to update market fee.
     * @param marketingFee market fee.
     */
    function updateMarketingFee( uint marketingFee) external onlyOwner { _marketFee = marketingFee; }
    
    /** 
     * @dev Calls _updateUseCaseFee() function to update usecase fee.
     * @param usecaseFee usecase fee.
     */
    function updateUseCaseFee( uint usecaseFee) external onlyOwner { _useCaseFee = usecaseFee; }
    
    /** 
     * @dev Calls _updateCharityWallet() function to update charity address.
     * @param charityWallet charity address.
     */
    function updateCharityWallet( address charityWallet) external onlyOwner { _charityFeeWallet = charityWallet; }
    
    /** 
     * @dev Calls _updateMarketingWallet() function to update market address.
     * @param marketingWallet market address.
     */
    function updateMarketingWallet( address marketingWallet) external onlyOwner { _marketFeeWallet = marketingWallet; }
    
    /** 
     * @dev Calls _updateUseCaseWallet() function to update usecase address.
     * @param usecaseWallet usecase address.
     */
    function updateUseCaseWallet( address usecaseWallet) external onlyOwner { _useCaseFeeWallet = usecaseWallet; }
    
    function updateisSwapEnableStatus( bool _status) external onlyOwner { isSwapEnable = _status; }
    
    function updateMaxAmountPerTx( uint maxAmountPerTx) external onlyOwner { _maxAmountPerTx = maxAmountPerTx; }
    
    function updateAddLPDelay( uint _addLPDelay) external onlyOwner { addLPDelay = _addLPDelay; }
    
    /** 
     * @dev Calls updateRouter() function to update router address.
     * @param _router router address.
     */
    function updateRouter( address _router) external onlyOwner {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }
    
    /** 
     * @dev Calls _approve() function to approve tokens to spender.
     * @param owner sender address.
     * @param spender receiver to send.
     * @param amount value to send.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "DXB:: approve : from the zero address");
        require(spender != address(0), "DXB:: approve : to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /** 
     * @dev Calls _transfer() function to transfer tokens to receive.
     * @param from sender address.
     * @param to receiver to send.
     * @param value value to send.
     */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "DXB :: _transfer : invaild to address");
        
        if(!isSwapEnable) monitorLiquidityAndEnableSwap();
        
        monitorReductionInFee();
        
        if((!isSwapEnable) || ((excludeFromDeduction[from]) || (excludeFromDeduction[to]))) removeAllFees(); // remove all fees.
        
        (uint _fLiquidity, uint _fburn, uint _faddlp, uint _value) = _computeFee( value);
        
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxAmountPerTx) contractTokenBalance = _maxAmountPerTx; 
        
        if ((isSwapEnable) && (lastAddLPTimestamp.add(addLPDelay) <= block.timestamp) && (!inSwapAndLiquifyLP) && (from != uniswapV2Pair) && (contractTokenBalance > 0) && (!inSwapAndLiquify)){
            lastAddLPTimestamp = block.timestamp;
            swapAndLiquify(contractTokenBalance);
            
            if((isSwapEnable) && (!inSwapAndLiquify) && (_fLiquidity > 0)  && (from != uniswapV2Pair) ) { _takeLiquidity(_fLiquidity); _swap(_fLiquidity); } // 50% 0f 5% - exchange DXB to BNB and send to the rewad pool contract
        }
        else {
            if((isSwapEnable) && (!inSwapAndLiquify) && (_fLiquidity > 0) && (!inSwapAndLiquifyLP)  && (from != uniswapV2Pair) ) { _takeLiquidity(_fLiquidity); _swap(_fLiquidity); } // 50% 0f 5% - exchange DXB to BNB and send to the rewad pool contract
        }
        
        _balances[from] = _balances[from].sub(_value);
        _balances[to] = _balances[to].add(_value);
        
        if(!excludeFromFeeBNB[from])
            IRewardPool(rewardPool).updateHolderLiquidity(from,1);
        
        if(!excludeFromFeeBNB[to])
            IRewardPool(rewardPool).updateHolderLiquidity(to,2);
        
        if(isSwapEnable){_takeLiquidity( _faddlp); if(_fburn > 0) _burn( from, _fburn);}
        
        if(reductionInTax) { cycleBurn(CycleBurn)._updateLPSupplyAndBurn(); }
        
        if((!isSwapEnable) || ((excludeFromDeduction[from]) || (excludeFromDeduction[to]))) resotreAllFees();
        
        emit Transfer(from, to, _value);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        _balances[address(this)] = _balances[address(this)].add(tLiquidity);
    }
    
    /** 
     * @dev Calls removeAllFees() function to remove all fees.
     */
    function removeAllFees() private {
        _restoreTaxFee = _taxFee;
        _restoreLiquidityFee = _liquidityFee;
        _restoreBurnFee = _burnFee;
        _restoreAddLPFee = _addLPFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _addLPFee = 0;
    }
    
    /** 
     * @dev Calls resotreAllFees() function to restore all fees.
     */
    function resotreAllFees() private {
        _taxFee = _restoreTaxFee;
        _liquidityFee = _restoreLiquidityFee;
        _burnFee = _restoreBurnFee;
        _addLPFee = _restoreAddLPFee;
        
        _restoreTaxFee = 0;
        _restoreLiquidityFee = 0;
        _restoreBurnFee = 0;
        _restoreAddLPFee = 0;
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwapLP {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        // emit wapAndLiquify(half, newBalance, otherHalf);
    }

    /** 
     * @dev Calls swapTokensForEth() function to exchange tokens to BNB from LP.
     * @param tokenAmount value for exchange.
     */
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
            block.timestamp
        );
    }

    /** 
     * @dev Calls addLiquidity() function to add liquidity to the LP.
     * @param tokenAmount amount to add.
     * @param ethAmount eth to add.
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    /** 
     * @dev Calls _computeFee() function to compute fees from transfer.
     * @param _amount value to compute fees.
     */
    function _computeFee(uint _amount) private view returns (uint _fliquidity, uint _fburn, uint _addlpfee, uint _value){
        uint _ftax = _amount.mul(_taxFee).div(100);
        _addlpfee = _amount.mul(_addLPFee).div(100);
        _fliquidity = _ftax.mul(_liquidityFee).div(100);
        _fburn = _ftax.mul(_burnFee).div(100);
        _value = _amount.sub(_ftax.add(_addlpfee));
    }
    
    /** 
     * @dev Calls _swap() function to exchange tokens for BNB.
     * @param _liquidity value to exchange.
     */
    function _swap(uint _liquidity) private lockTheSwap returns (bool){
        if(_liquidity == 0) return false;
        
        uint _balance = address(this).balance;
        
        swapTokensForBNB(_liquidity);
        
        uint _currentBNBLiquidity = address(this).balance;
        
        if(_currentBNBLiquidity > _balance){
            _currentBNBLiquidity = _currentBNBLiquidity.sub(_balance);
            uint _feeCharity = _currentBNBLiquidity.mul(_charityFee).div(100);
            uint _feeMarket = _currentBNBLiquidity.mul(_marketFee).div(100);
            uint _feeUseCase = _currentBNBLiquidity.mul(_useCaseFee).div(100);
            
            require(payable(_charityFeeWallet).send(_feeCharity), "Transfer 10% BNB to charity");
            require(payable(_marketFeeWallet).send(_feeMarket), "Transfer 10% BNB to marketing");
            require(payable(_useCaseFeeWallet).send(_feeUseCase),"Transfer 10% BNB to Usecase");
            
            uint _rewardPoolValue = _currentBNBLiquidity.sub((_feeCharity.add(_feeMarket).add(_feeUseCase)));
            if(_rewardPoolValue == 0) return true;
            
            require(payable(rewardPool).send(_rewardPoolValue), "Transfer BNB to reward pool");
            IRewardPool(rewardPool).updatePool(_rewardPoolValue);
        }
        
        return true;        
    }
    
    /** 
     * @dev Calls swapTokensForBNB() function to exchange tokens for BNB.
     * @param tokenAmount value to exchange.
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
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
            block.timestamp
        );
    }
    
    /** 
     * @dev Calls montiorLiquidityAndEnableSwap() function to enable fees.
     */
    function monitorLiquidityAndEnableSwap() private {
      uint112 _reserveDXB=0;
      if(IUniswapV2Pair(uniswapV2Pair).token0() == address(this)){
          (_reserveDXB, ,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
      }
      else{
          (,_reserveDXB,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
      }
      
      if(_reserveDXB > 0) {
          isSwapEnable = true; 
          cycleBurn(CycleBurn).updatelpSupply( _reserveDXB);
        //   cycleBurn(CycleBurn).updateStartBlock(block.timestamp);
      }
      else { isSwapEnable = false; }
    }
    
    /** 
     * @dev Calls monitorReductionInFee() function to enable reduction in fee.
     */
    function monitorReductionInFee() private {
        if((totalSupply() <= _rInSupply) && (reductionInTax)){
            _taxFee = 2;
            _liquidityFee = 100;
            _burnFee = 0;
            _charityFee = 25;
            _marketFee = 25;
            _useCaseFee = 50;
            reductionInTax = false;
        }
    }
    
    /** 
     * @dev Calls mint() function to mint tokens for accounts.
     * @param account mint account.
     * @param value value to mint.
     */
    function mint(address account, uint256 value) internal {
        require(account != address(0), "DXB :: mint : invaild account");
 
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
 
    /** 
     * @dev Calls _burn() function to burn tokens.
     * @param _account burn account.
     * @param value value to burn.
     */
    function _burn( address _account, uint256 value) private {
        _balances[_account] = _balances[_account].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(_account, value);
        emit Transfer(_account, address(0), value);
    }
}