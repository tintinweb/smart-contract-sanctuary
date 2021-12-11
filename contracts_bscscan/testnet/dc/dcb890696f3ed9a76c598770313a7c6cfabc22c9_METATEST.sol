/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function Z_transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract METATEST is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee; // exempt from paying any fees
    mapping (address => bool) private _isExcludedRewards; // exempt from receiving reflections
    address[] private _excluded;

    uint8 private _decimals = 7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**_decimals; // 1 Billion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "META TEST";
    string private _symbol = "META14";
   
    address public _marketingWallet;
    address public _productDevelopmentWallet;
    address public _communityWallet;
    address public _blockchainSupportWallet;
    

    uint256 public impact1 = 100; // 1% price impact = 100
    uint256 public impact2 = 500; // 5% price impact = 500 (to disable set it to 10000)
                                   
    // All fees are a percentage number

    //Project funding fee
    uint256 public  projectFee = 10; // this may change in sell and buy functions
    uint256 private previousProjectFee;
 
    // Project funding fee split 
    // Important: 
    // marketingFee + productDevelopmentFee + blockchainSupportFee = 100 <-- Mandatory rule !
    //
    uint256 public marketingFee = 60;          // Percentage of projectFee
    uint256 public productDevelopmentFee = 30; // Percentage of projectFee
    uint256 public blockchainSupportFee = 10;  // Percentage of projectFee

    // Reflections - free tokens distribution
    //               to holders (passive income)
    uint256 public  reflectionsFee = 1; // this may change in sell and buy functions
    uint256 private previousReflectionsFee;

    uint256 public transfer_ProjectFee = 5;
    uint256 public transfer_ReflectionsFee = 0;

    uint256 public buy_ProjectFee = 10;
    uint256 public buy_ReflectionsFee = 0;

    uint256 public sell_ProjectFee_A = 10; // Lowest fee up to price impact1
    uint256 public sell_ProjectFee_B = 20; // Higher fee when between price impact1 and impact2
    uint256 public sell_ProjectFee_C = 30; // Highest fee above price impact2 (to disable set it same as B)
          
    uint256 public sell_ReflectionsFee_A = 1; // Up to price impact1
    uint256 public sell_ReflectionsFee_B = 2; // Between price impact1 and impact2
    uint256 public sell_ReflectionsFee_C = 3; // Above price impact2
  
    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_ProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;
 
    // A Manager has 99% same control rights as Owner (is usually a CTO or co-Founder)
    // Tip:  Owner can add his/her second wallet to Managers for a backup control access.
    //       Only the Owner can add or remove a Manager 
    mapping(address => bool) public Managers;

    // Blockchain Support Dev Team. 
    // It is initally a partner company. Can be handed over to project own Dev team.
    // Has almost no control of the smart contract. Can only do this:  
    // Can change the _blockchainSupportWallet to auto charge for provided services 
    mapping(address => bool) public BlockchainDevs; 

    mapping(address => uint256) private sell_AllowedTime;
    uint256 public sell_AntiDump_Wait_Secs = 60;
    bool private antiDumpEnabled = false;

    uint256 public maxSellTokensAmount = _tTotal; // Default: Max supply (no restrictions)
    uint256 public minSellTokenAmount = 0;        // Default: Zero (no restrictions)
                
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public  AllFeesEnabled = true;
    bool private isTrade = true;
    
    bool ProjectFundingSwapMode;
    bool public tradingEnabled = false;
    uint256 public minTokensSwapToProjectFunds = 100000 * 10**_decimals; // 0.01%

    event ProjectFundingDone(
        uint256 tokensSwapped,
        address indexed address01,
		uint256 amount01,
		address indexed address02,
		uint256 amount02
    );
    event TokensSentToCommunityWallet (
		address indexed recipient,
		uint256  amount
	);
    event Added_Manager(address indexed account);
    event Removed_Manager(address indexed account);
    event Added_BlockchainDev(address indexed account);
    event Removed_BlockchainDev(address indexed account);
    event Updated_MaxSell_TokenAmount(uint256 maxSellTokensAmount);
    event Updated_MinSell_TokenAmount(uint256 minSellTokenAmount);

    modifier lockTheSwap {
        ProjectFundingSwapMode = true;
        _;
        ProjectFundingSwapMode = false;
    }
    modifier onlyManager() {
       require(Managers[msg.sender] || msg.sender == owner(), "You are not Manager or Owner");
        _;
    }
    modifier onlyDev() {
       require(BlockchainDevs[msg.sender], "You are not a Blockchain Support Team member");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // PancakeSwap V2 Router
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); 

         // Create a pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _marketingWallet = msg.sender;
        _productDevelopmentWallet = msg.sender;
        _communityWallet = msg.sender;
        _blockchainSupportWallet = msg.sender;
        
        BlockchainDevs[msg.sender] = true;
        
        
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
        if (_isExcludedRewards[account]) return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }
    function checkif_ExcludedFromReflections(address account) public view returns (bool) {
        return _isExcludedRewards[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address is not allowed");
        require(spender != address(0), "Approve to the zero address is not allowed");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Transfer from the zero address is not allowed");
        require(to != address(0), "Transfer to the zero address is not allowed");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[from], "Sender address is blacklisted");
		require(!isBlacklisted[to], "Recipient address is blacklisted");
        
        if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "Trading is disabled");
        }
        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            
            if (to != address(uniswapV2Router)) {
                isTrade = true;
                projectFee = buy_ProjectFee; 
                reflectionsFee = buy_ReflectionsFee;
            }
            if (from != uniswapV2Pair && to != address(uniswapV2Pair)) {
                isTrade = false;

                if (BridgeOrExchange[from]) {
                        projectFee = BridgeOrExchange_ProjectFee[from];
                        reflectionsFee = BridgeOrExchange_ReflectionsFee[from];
                }
                else if (BridgeOrExchange[to]) {
                        projectFee = BridgeOrExchange_ProjectFee[to];
                        reflectionsFee = BridgeOrExchange_ReflectionsFee[to];
                }
                else {
                        projectFee = transfer_ProjectFee; 
                        reflectionsFee = transfer_ReflectionsFee;
                }            
            }
            if (from != uniswapV2Pair && to == address(uniswapV2Pair) && from != address(this)) {
                require(amount <= maxSellTokensAmount, "Anti-Dump measure. Token amount exceeds the max amount.");
                require(amount >= minSellTokenAmount, "Anit-Bot measure. Token amount insufficient.");
                
                isTrade = true;

                if (antiDumpEnabled) {
                    require(block.timestamp > sell_AllowedTime[from]);
                }
                if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(impact1)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(impact1));
                    projectFee = sell_ProjectFee_A;
                    reflectionsFee = sell_ReflectionsFee_A;

                } else if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(impact2)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(impact2));
                    projectFee = sell_ProjectFee_B;
                    reflectionsFee = sell_ReflectionsFee_B;
                    
                } else {
                    projectFee = sell_ProjectFee_C;
                    reflectionsFee = sell_ReflectionsFee_C;
                }   
            }           
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= maxSellTokensAmount)
        {
           contractTokenBalance = maxSellTokensAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= minTokensSwapToProjectFunds;
        if (
            overMinTokenBalance &&
            !ProjectFundingSwapMode &&
            from != uniswapV2Pair
        ) {
            projectFundingSwap(contractTokenBalance);
        }        
        //indicates if fee should be deducted from transfer
        bool takeAllFees = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !AllFeesEnabled){
            takeAllFees = false;
        }        
        _tokenTransfer(from,to,amount,takeAllFees);
        restoreAllFees;

        if (isTrade && antiDumpEnabled) {
            sell_AllowedTime[from] = block.timestamp + sell_AntiDump_Wait_Secs;
        }
    }
    function projectFundingSwap(uint256 contractTokenBalance) private lockTheSwap {
        
        // check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        // calculate the percentages
        uint256 marketingBNB = BalanceBNB.div(100).mul(marketingFee);
        uint256 productDevelopmentBNB = BalanceBNB.div(100).mul(productDevelopmentFee);
        uint256 blockchainSupportBNB = BalanceBNB.div(100).mul(blockchainSupportFee);   

        //pay the Blockchain Support Team wallet
        payable(_blockchainSupportWallet).transfer(blockchainSupportBNB); 

        //pay the Marketing wallet
        payable(_marketingWallet).transfer(marketingBNB);

        //pay the Product Development wallet
        payable(_productDevelopmentWallet).transfer(productDevelopmentBNB);

        emit ProjectFundingDone(tokensbeforeSwap, _marketingWallet, marketingBNB, _productDevelopmentWallet, productDevelopmentBNB);  
    }
    function swapTokensForBNB(uint256 tokenAmount) private {
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
    //this method is responsible for taking all fee, if takeAllFees is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeAllFees) private {
        if(!takeAllFees)
            removeAllFees();
        
        if (_isExcludedRewards[sender] && !_isExcludedRewards[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedRewards[sender] && _isExcludedRewards[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedRewards[sender] && !_isExcludedRewards[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedRewards[sender] && _isExcludedRewards[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeAllFees)
            restoreAllFees();
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeProjectFee(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeProjectFee(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeProjectFee(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeProjectFee(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionsFee(tAmount);
        uint256 tLiquidity = calculateProjectFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }    
    function _takeProjectFee(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        if (isTrade) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcludedRewards[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        } else {
            _rOwned[address(_communityWallet)] = _rOwned[address(_communityWallet)].add(rLiquidity);
            emit TokensSentToCommunityWallet(_communityWallet, rLiquidity);

            if(_isExcludedRewards[address(_communityWallet)])
            _tOwned[address(_communityWallet)] = _tOwned[address(_communityWallet)].add(tLiquidity); 
            emit TokensSentToCommunityWallet(_communityWallet, tLiquidity);
        }
    }
    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(reflectionsFee).div(100);
    }    
    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(projectFee).div(100);
    }    
    function removeAllFees() private {
        if(reflectionsFee == 0 && projectFee == 0) return;
        
        previousReflectionsFee = reflectionsFee;
        previousProjectFee = projectFee;
        
        reflectionsFee = 0;
        projectFee = 0;
    }    
    function restoreAllFees() private {
        reflectionsFee = previousReflectionsFee;
        projectFee = previousProjectFee;
    }   

    // Security

    function A1_addToBlacklist_BadActor(address account) public onlyManager {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted");      
     	require(account != owner(), "Owner cannot be blacklisted");
        require(account != _blockchainSupportWallet, "Blockchain Support wallet cannot be blacklisted");	
        require(account != address(this), "Token contract cannot be blacklisted");
        require(!BlockchainDevs[account], "Blockchain Support Team accounts cannot be blacklisted");		
		require(!isBlacklisted[account], "Address is already blacklisted");	

        isBlacklisted[account] = true;
    }
    function A2_removeFromBlacklist(address account) public onlyManager {
        require(isBlacklisted[account], "Address is already whitelisted");

        isBlacklisted[account] = false;
    }
	function A3_checkif_Blacklisted(address account) public view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    
    // Anti-Dump settings

    function B1_check_AntiDump_sellWait_Enabled() public view returns (bool) {
        //True  - waiting time between sells enabled 
        //False - there is no waiting time restriction
        return antiDumpEnabled;
    }
    function B2_get_AntiDump_SellWait_Duration() public view returns (uint256) {
        // Show waiting time in seconds between sells (use B1 to check if enabled)
        return sell_AntiDump_Wait_Secs;
    }
    function B3_enable_AntiDump_sellWait() external onlyManager() {
        //Make sure to set also the waiting duration (see B5) 
        antiDumpEnabled = true;
    }    
    function B4_disable_AntiDump_sellWait() external onlyManager() {
        // Remove restriction on waiting time between sells
        antiDumpEnabled = false;
    }
    function B5_set_AntiDump_SellWait_Duration(uint256 Wait_Secs) external onlyManager() {
        // Set waiting time between sells in seconds (use B3 to enable it) 
        sell_AntiDump_Wait_Secs = Wait_Secs;
    }
    function B6_set_MaxSell_TokenAmount(uint256 maxTokenAmount) external onlyManager() {
        // Set max tokens amount for sells
        // Example: 200 tokens = minTokenAmount = 2000000000 (200 + _decimals)
        maxSellTokensAmount = maxTokenAmount;
        emit Updated_MaxSell_TokenAmount(maxSellTokensAmount);
    }
    function B7_set_MinSell_TokenAmount(uint256 minTokenAmount) external onlyManager() {
        // Use this e.g. to disturb bots strategies and 
        // bots doing calculations with very small trades
        // Example: 100 tokens = minTokenAmount = 1000000000 (100 + _decimals)
        minSellTokenAmount = minTokenAmount;
        emit Updated_MinSell_TokenAmount(minSellTokenAmount);
    }
    function B7_set_MinTokensSwap_ProjectFunding(uint256 minTokenAmount) external onlyManager() {
        // Example: 100000 tokens = minTokenAmount = 1000000000000 (100000 + _decimals) = 0.01%
        minTokensSwapToProjectFunds = minTokenAmount;
    }

    // Trading, price impact and fees

    function C01_enable_Trading() external onlyManager() {
        tradingEnabled = true;
    }
    function C02_disable_Trading() external onlyManager() {
        tradingEnabled = false;
    }
    function C03_enable_All_Fees() external onlyManager() {
        // Enable project and reflections fees
        AllFeesEnabled = true;
    }
    function C04_disable_All_Fees() external onlyManager() {
        // Disable project and reflections fees
        AllFeesEnabled = false;
    }
    function C05_set_Sell_Price_Impact1(uint256 _impact1) external onlyManager {
        // Examples:  1% price impact = impact1 = 100
        //          0.5% price impact = impact1 =  50  
        impact1 = _impact1;
    }
    function C06_set_Sell_Price_Impact2(uint256 _impact2) external onlyManager {
        // Example: 5% price impact = impact2 = 500 
        impact2 = _impact2;
        // To disable the price impact2 tier then set impact2 = 10000
        // or set in C18 the sell_ProjectFee_C same as sell_ProjectFee_B
    }
    function C07_set_ProjectFundingFee(uint256 fee_percent) external onlyManager() {
        // Example: 10% fee = fee_percent = 10 
        projectFee = fee_percent;
        // Project fee is then split in smaller pieces (see C08, C09 and C10)
    }
    function C08_set_MarketingFee(uint256 fee_percent) external onlyManager() {
        // Example: 60% of projectFee = fee_percent = 60
        // Important: 
        // MarketingFee + ProductDevelopmentFee + BlockchainSupportFee = 100 <-- Mandatory rule !   
        marketingFee = fee_percent;
    }
    function C09_set_ProductDevelopmentFee(uint256 fee_percent) external onlyManager() {
        // Example: 30% of projectFee = fee_percent = 30
        // Important: 
        // MarketingFee + ProductDevelopmentFee + BlockchainSupportFee = 100 <-- Mandatory rule !
        productDevelopmentFee = fee_percent;
    }
    /*
    //   If function C10 is disabled then the Blockchain Support services
    //   are provided by a partner or external company. Also so to ensure
    //   the contractual agreement and for mutual safety reasons.
    //
    function C10_set_BlockchainSupportFee(uint256 fee_percent) external onlyManager() {
        // Example: 10% of projectFee = fee_percent = 10
        // Important: 
        // MarketingFee + ProductDevelopmentFee + BlockchainSupportFee = 100 <-- Mandatory rule !
        blockchainSupportFee = fee_percent;
    }
    */
    function C11_set_Buy_ProjectFee(uint256 fee_percent) external onlyManager() {
        buy_ProjectFee = fee_percent;
    }
    function C12_set_Buy_ReflectionsFee(uint256 fee_percent) external onlyManager() {
        buy_ReflectionsFee = fee_percent;
    }
    function C13_set_Default_ReflectionsFee(uint256 fee_percent) external onlyManager() {
        // This function is normally not used
        reflectionsFee = fee_percent;
    }
    function C14_set_Transfer_ProjectFee(uint256 fee_percent) external onlyManager() {
        // Set project fee for transfers from wallet to wallet
        transfer_ProjectFee = fee_percent;
    }
    function C15_set_Transfer_ReflectionsFee(uint256 fee_percent) external onlyManager() {
        // Set reflections fee for transfers from wallet to wallet
        transfer_ReflectionsFee = fee_percent;
    }
    function C16_set_sell_ProjectFee_A(uint256 fee_percent) external onlyManager() {
        // Set project fee up to price impact1
        sell_ProjectFee_A = fee_percent;
    }
    function C17_set_sell_ProjectFee_B(uint256 fee_percent) external onlyManager() {
        // Set project fee between price impact1 and impact2
        sell_ProjectFee_B = fee_percent;
    }
    function C18_set_sell_ProjectFee_C(uint256 fee_percent) external onlyManager() {
        // Set project fee above price impact 2.
        // To disable this tier set this fee to same fee as sell_ProjectFee_B
        // or set in C06 impact2 = 10000    
        sell_ProjectFee_C = fee_percent;
    }
    function C19_set_sell_ReflectionsFee_A(uint256 fee_percent) external onlyManager() {
        // Set reflection fee up to price impact1
        sell_ReflectionsFee_A = fee_percent;
    }
    function C20_set_sell_ReflectionsFee_B(uint256 fee_percent) external onlyManager() {
        // Set reflection fee between price impact1 and impact2
        sell_ReflectionsFee_B = fee_percent;
    }
    function C21_set_sell_ReflectionsFee_C(uint256 fee_percent) external onlyManager() {
        // Set project fee above price impact 2 
        sell_ReflectionsFee_C = fee_percent;
    }
    function C22_enable_isChargedFees(address account) public onlyManager {
        // Enable will be charged all fees (project and reflections fees)
        _isExcludedFromFee[account] = false;
    }
    function C23_isExcludedFromFees(address account) public onlyManager {
        // Exempt from paying any fees
        _isExcludedFromFee[account] = true;
    }
    function C24_checkif_ExcludedFromFees(address account) public view returns(bool) {
        // True  - Is exempted from paying any fees
        // False - Is charged all fees (project and reflections fees)
        return _isExcludedFromFee[account];
    }
    function C25_enable_receive_Reflections(address account) external onlyManager() {
        require(_isExcludedRewards[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function C26_excludeFromReflections(address account) public onlyManager() {
        // Will not receive reflections
        require(!_isExcludedRewards[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedRewards[account] = true;
        _excluded.push(account);
    }   

    // Project fee split to wallets

    function D1_set_MarketingWallet(address account) public onlyManager() {
        _marketingWallet = account;
    }
    function D2_set_ProductDevelopmentWallet(address account) public onlyManager() {
        _productDevelopmentWallet = account;
    }
    function D3_set_CommunityWallet(address account) public onlyManager() {
        _communityWallet = account;
    }
    function D4_set_BlockchainSupportWallet(address account) public onlyDev() {
        _blockchainSupportWallet = account;
    }

    // Managers Team & Blockchain Support Team members

    function E1_add_Manager(address account) external onlyOwner {
        require(!Managers[account],"Manager already added");
        Managers[account] = true;
        emit Added_Manager(account);
    }
    function E2_add_BlockchainDev(address account) external onlyDev {
        require(!BlockchainDevs[account],"Blockchain Dev already added");
        BlockchainDevs[account] = true;
        emit Added_BlockchainDev(account);
    }
    function E3_remove_Manager(address account) external onlyOwner {
        require(Managers[account],"Cannot remove. There is no Manager with this address");
        Managers[account] = false;
        emit Removed_Manager(account);
    }
    function E4_remove_BlockchainDev(address account) external onlyDev {
        require(BlockchainDevs[account],"Canot remove. There is no Dev with this address");
        BlockchainDevs[account] = false;
        emit Removed_BlockchainDev(account);
    }
	function E5_check_Manager(address account) public view returns (bool) {   
        return Managers[account];
    }
    function E6_check_BlockchainDev(address account) public view returns (bool) {   
        return BlockchainDevs[account];
    }

    // Bridges and Exchanges 

    function F1_add_BridgeOrExchange(address account, uint256 proj_fee, uint256 reflections_fee) public onlyManager {
        BridgeOrExchange[account] = true;
        BridgeOrExchange_ProjectFee[account] = proj_fee;
        BridgeOrExchange_ReflectionsFee[account] = reflections_fee;
    }
    function F2_remove_BridgeOrExchange(address account) public onlyManager {
        delete BridgeOrExchange[account];
        delete BridgeOrExchange_ProjectFee[account];
        delete BridgeOrExchange_ReflectionsFee[account];
    }
    function F3_check_BridgeOrExchange(address account) public view returns (bool) {
        return BridgeOrExchange[account];
    }
    function F4_get_BridgeOrExchange_ProjectFee(address account) public view returns (uint256) {
        return BridgeOrExchange_ProjectFee[account];
    }
    function F5_get_BridgeOrExchange_ReflectionsFee(address account) public view returns (uint256) {
        return BridgeOrExchange_ReflectionsFee[account];
    }

     //To recieve BNB from PancakeSwap V2 Router when swaping
    receive() external payable {}
}