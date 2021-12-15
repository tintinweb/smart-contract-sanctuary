/**
 *Submitted for verification at BscScan.com on 2021-12-15
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

    event Ownership_Transferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit Ownership_Transferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Aborted. You are not the Owner");
        _;
    }
    function Z_transfer_Ownership(address newOwner) public virtual onlyOwner {
        // IMPORTANT: 
        // Usually one needs also to execute C20_enable_mustPayFees function
        // if the old Owner will not be excluded from paying fees anymore
        // Also rememebr to run C21_exclude_fromPayingFees for the new Owner 
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit Ownership_Transferred(_previousOwner, newOwner);
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

contract GOALTEST is Context, IERC20, Ownable {
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
    uint256 private _tTotal = 500000000 * 10**_decimals; // 500 Million
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "GOAL TEST v1";
    string private _symbol = "GOAL_TEST_v1";
   
    address public FondoBNB_wallet;
    address public ReservaTokens_wallet;

    address public BlockchainSupport_wallet;

    uint256 public price_impact1 = 10; // 0.1% price impact
    uint256 public price_impact2 = 20; // 0.2% price impact (to disable set this to 10000)
                                   
    // All fees are a percentage number

    //Project funding fee
    uint256 public  projectFee = 15; // this may change in sell and buy functions
    uint256 private previousProjectFee;
 
    // Project funding fee split 
    // Important: 
    // FondoBNB_Fee + BlockchainSupport_Fee = 100 <-- Mandatory rule !
    //
    uint256 public FondoBNB_Fee = 96;          // Percentage of projectFee
    uint256 public BlockchainSupport_Fee = 4;  // Percentage of projectFee

    // Reflections - free tokens distribution
    //               to holders (passive income)
    uint256 public  reflectionsFee = 0; // this may change in sell and buy functions
    uint256 private previousReflectionsFee;

    uint256 public transfer_ProjectFee = 5;
    uint256 public transfer_ReflectionsFee = 0;

    uint256 public buy_ProjectFee = 5;
    uint256 public buy_ReflectionsFee = 0;

    uint256 public sell_ProjectFee_A = 15; // Lowest fee up to price impact1
    uint256 public sell_ProjectFee_B = 20; // Higher fee when between price impact1 and impact2
    uint256 public sell_ProjectFee_C = 30; // Highest fee above price impact2 (to disable set this same as B)
          
    uint256 public sell_ReflectionsFee_A = 0; // Up to price impact1
    uint256 public sell_ReflectionsFee_B = 0; // Between price impact1 and impact2
    uint256 public sell_ReflectionsFee_C = 0; // Above price impact2
  
    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_ProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;
 
    // Blockchain Support Dev Team. 
    // Has no control of the smart contract except this:  
    // Can only change the BlockchainSupport_wallet to auto charge for provided services 
    mapping(address => bool) private BlockchainSupportDevs; 

    mapping(address => uint256) private sell_AllowedTime;
    uint256 public antiDump_SellWait_Duration_Seconds = 120;
    bool public antiDump_SellWait_Enabled = false;
                
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public  AllFeesEnabled = true;
    bool private isTrade = true;
    
    bool ProjectFundingSwapMode;
    bool public Public_Trading_Enabled = false;

    uint256 public minTokensForProjectFundingSwap = 50000 * 10**_decimals; // 0.01%

    event ProjectFundingDone(
        uint256 tokensSwapped,
        address indexed address01,
		uint256 amount01,
		address indexed address02,
		uint256 amount02
    );
    event TokensSentToReservaWallet (
		address indexed recipient,
		uint256  amount
	);
    event Added_BlockchainSupportDev(address indexed account);
    event Removed_BlockchainSupportDev(address indexed account);


    modifier lockTheSwap {
        ProjectFundingSwapMode = true;
        _;
        ProjectFundingSwapMode = false;
    }
    modifier onlyBlockchainDev() {
       require(BlockchainSupportDevs[msg.sender], "You are not a Blockchain Support Team member");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // PancakeSwap V2 Router
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 

         // Create a pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // Exclude owner and this contract from all fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        FondoBNB_wallet = msg.sender;
        BlockchainSupport_wallet = msg.sender;
        ReservaTokens_wallet = msg.sender;
        
        BlockchainSupportDevs[msg.sender] = true;
        
        
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
        require(Public_Trading_Enabled || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Public Trading has not been enabled yet.");
        
        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                isTrade = true;
                projectFee = buy_ProjectFee; 
                reflectionsFee = buy_ReflectionsFee;
            }
            if (to == uniswapV2Pair && from != uniswapV2Pair ) {

                isTrade = true;

                if (antiDump_SellWait_Enabled) {
                    require(block.timestamp > sell_AllowedTime[from]);
                }
                if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(price_impact1)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(price_impact1));
                    projectFee = sell_ProjectFee_A;
                    reflectionsFee = sell_ReflectionsFee_A;

                } else if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(price_impact2)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(price_impact2));
                    projectFee = sell_ProjectFee_B;
                    reflectionsFee = sell_ReflectionsFee_B;
                    
                } else {
                    projectFee = sell_ProjectFee_C;
                    reflectionsFee = sell_ReflectionsFee_C;
                }   
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
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
                        
                        if (antiDump_SellWait_Enabled) {
                        // To prevent evading the sell waiting time by sending to 
                        // another wallet and then selling from it we set a sell
                        // waiting time also for the transfer recipient wallet  
                        sell_AllowedTime[to] = block.timestamp + antiDump_SellWait_Duration_Seconds;
                    }
                }            
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        // ProjectFundingSwap i.e. selling done by the token contract 
        // is purposely set not be executed during a buy trade. We have
        // observed that if/when the contract sells immediately after 
        // a buy trade it may look like there is a bot that is constantly
        // selling on people buys.    
        bool overMinTokenBalance = contractTokenBalance >= minTokensForProjectFundingSwap;
        if (
            overMinTokenBalance &&
            !ProjectFundingSwapMode && 
            from != uniswapV2Pair 
        ) {
            projectFundingSwap(contractTokenBalance);
        }        
        //indicates if fees should be deducted from transfer
        bool takeAllFees = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !AllFeesEnabled){
            takeAllFees = false;
        }        
        _tokenTransfer(from,to,amount,takeAllFees);
        restoreAllFees;

        if (isTrade && antiDump_SellWait_Enabled) {
            sell_AllowedTime[from] = block.timestamp + antiDump_SellWait_Duration_Seconds;
        }
    }
    function projectFundingSwap(uint256 contractTokenBalance) private lockTheSwap {
        
        // check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        // calculate the percentages
        uint256 fondoBNB = BalanceBNB.div(100).mul(FondoBNB_Fee);
        uint256 blockchainSupportBNB = BalanceBNB.div(100).mul(BlockchainSupport_Fee);   

        //pay the Blockchain Support Team wallet
        payable(BlockchainSupport_wallet).transfer(blockchainSupportBNB); 

        //pay the project funding wallet
        payable(FondoBNB_wallet).transfer(fondoBNB);

        emit ProjectFundingDone(tokensbeforeSwap, FondoBNB_wallet, fondoBNB, BlockchainSupport_wallet, blockchainSupportBNB);  
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
    // this method is responsible for taking all fee, if takeAllFees is true
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
            _rOwned[address(ReservaTokens_wallet)] = _rOwned[address(ReservaTokens_wallet)].add(rLiquidity);
            emit TokensSentToReservaWallet(ReservaTokens_wallet, rLiquidity);

            if(_isExcludedRewards[address(ReservaTokens_wallet)])
            _tOwned[address(ReservaTokens_wallet)] = _tOwned[address(ReservaTokens_wallet)].add(tLiquidity); 
            emit TokensSentToReservaWallet(ReservaTokens_wallet, tLiquidity);
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

    function A1_Blacklist_BadActor(address account) external onlyOwner {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted");      
     	require(account != owner(), "Owner cannot be blacklisted");
        require(account != BlockchainSupport_wallet, "Blockchain Support wallet cannot be blacklisted");	
        require(account != address(this), "Token contract cannot be blacklisted");
        require(!BlockchainSupportDevs[account], "Blockchain Support Team accounts cannot be blacklisted");		
		require(!isBlacklisted[account], "Address is already blacklisted");	

        isBlacklisted[account] = true;
    }
    function A2_removeFromBlacklist(address account) external onlyOwner {
        require(isBlacklisted[account], "Address is already whitelisted");

        isBlacklisted[account] = false;
    }
	function A3_checkif_Blacklisted(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    
    // Anti-Dump sell waiting settings

    function B1_check_sell_AllowedTime(address account) external view returns (string memory, uint256) {
        // If AntiDump sell waiting time is enabled then this function
        // can be used to check when it is the earliest time an account can sell.
        require (balanceOf(account) > 0, "Account has no tokens"); 
        string memory Message = " The time format is Unix time."
                                "  Tip: Use free online time conversion websites"
                                " to convert from Unix time to a date and time.";
        return (Message, sell_AllowedTime[account]);     
    }
    function B2_enable_AntiDump_sellWait() external onlyOwner {
        //Make sure to set also the waiting duration with B4  
        antiDump_SellWait_Enabled = true;
    }    
    function B3_disable_AntiDump_sellWait() external onlyOwner {
        // Remove the restriction on waiting time between sells
        antiDump_SellWait_Enabled = false;
    }
    function B4_set_AntiDump_SellWait_Duration(uint256 wait_seconds) external onlyOwner {
        // Set a waiting time between sells in seconds 
        // For this to take effect it must also be enabled with B2 function. 
        antiDump_SellWait_Duration_Seconds = wait_seconds;
    }
    function B5_set_MinTokens_ForProjectFundingSwap(uint256 minTokenAmount) external onlyOwner {
        // Example: 50000 tokens = minTokenAmount = 500000000000 (50000 + _decimals) = 0.01%
        minTokensForProjectFundingSwap = minTokenAmount;
    }

    // Trading, price impacts tiers and fees

    function C01_enable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = true;
    }
    function C02_disable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = false;
    }
    function C03_enable_All_Fees() external onlyOwner {
        // Enable project and reflections fees
        AllFeesEnabled = true;
    }
    function C04_disable_All_Fees() external onlyOwner {
        // Disable project and reflections fees
        AllFeesEnabled = false;
    }
    function C05_set_Sell_Price_Impact1(uint256 impact1) external onlyOwner {
        // Examples:  1% price impact = impact1 = 100
        //          0.1% price impact = impact1 =  10  
        price_impact1 = impact1;
    }
    function C06_set_Sell_Price_Impact2(uint256 impact2) external onlyOwner {
        // Example: 5% price impact = impact2 = 500 
        price_impact2 = impact2;
        // To disable the price impact2 tier then set impact2 = 10000 (100%)
        // Or set with C17 function the sell_ProjectFee_C to the same fee 
        // as the sell_ProjectFee_B
    }
    function C07_set_ProjectFundingFee(uint256 fee_percent) external onlyOwner {
        // Example: 15% fee = fee_percent = 15 
        projectFee = fee_percent;
        // Project fee is in turn split in smaller pieces 
        // Use functions C08 and C09 to split it further 
    }
    function C08_set_FondoBNB_Fee(uint256 fee_percent) external onlyOwner {
        // Example: 90% of projectFee = fee_percent = 90
        // IMPORTANT: 
        // FondoBNB_Fee + BlockchainSupport_Fee = 100 <-- Mandatory rule !   
        FondoBNB_Fee = fee_percent;
    }
    //  If function C09 is disabled then the Blockchain Support services are provided
    //  (or were initially provided) by a Partner or an external company. It is also 
    //  so to ensure the contractual agreement and for mutual safety reasons and trust.
    //
    //  function C09_set_BlockchainSupport_Fee(uint256 fee_percent) external onlyOwner {
    //      Example: 10% of projectFee = fee_percent = 10
    //      IMPORTANT: 
    //      FondoBNB_Fee + BlockchainSupport_Fee = 100 <-- Mandatory rule !
    //      BlockchainSupport_Fee = fee_percent;
    //}

    function C10_set_Buy_ProjectFee(uint256 fee_percent) external onlyOwner {
        buy_ProjectFee = fee_percent;
    }
    function C11_set_Buy_ReflectionsFee(uint256 fee_percent) external onlyOwner {
        buy_ReflectionsFee = fee_percent;
    }
    function C12_set_Default_ReflectionsFee(uint256 fee_percent) external onlyOwner {
        // This function is normally not used
        reflectionsFee = fee_percent;
    }
    function C13_set_Transfer_ProjectFee(uint256 fee_percent) external onlyOwner {
        // Set project fee for transfers from wallet to wallet
        transfer_ProjectFee = fee_percent;
    }
    function C14_set_Transfer_ReflectionsFee(uint256 fee_percent) external onlyOwner {
        // Set reflections fee for transfers from wallet to wallet
        transfer_ReflectionsFee = fee_percent;
    }
    function C15_set_sell_ProjectFee_A(uint256 fee_percent) external onlyOwner {
        // Set project fee up to price impact1
        sell_ProjectFee_A = fee_percent;
    }
    function C16_set_sell_ProjectFee_B(uint256 fee_percent) external onlyOwner {
        // Set project fee between price impact1 and impact2
        sell_ProjectFee_B = fee_percent;
    }
    function C17_set_sell_ProjectFee_C(uint256 fee_percent) external onlyOwner {
        // Set project fee above price impact2.
        // To disable this tier set this fee to same as sell_ProjectFee_B
        // or set in C06 the price impact to 100% i.e. set impact2 = 10000    
        sell_ProjectFee_C = fee_percent;
    }
    function C18_set_sell_ReflectionsFee_A(uint256 fee_percent) external onlyOwner {
        // Set reflection fee for sells up to price impact1
        sell_ReflectionsFee_A = fee_percent;
    }
    function C19_set_sell_ReflectionsFee_B(uint256 fee_percent) external onlyOwner {
        // Set reflection fee for sells between price impact1 and impact2
        sell_ReflectionsFee_B = fee_percent;
    }
    function C20_set_sell_ReflectionsFee_C(uint256 fee_percent) external onlyOwner {
        // Set project fee for sells above price impact 2 
        sell_ReflectionsFee_C = fee_percent;
    }
    function C21_enable_mustPayFees(address account) external onlyOwner {
        // Enable will be charged all fees
        // i.e. will pay both project and reflections fees
        _isExcludedFromFee[account] = false;
    }
    function C22_exclude_fromPayingFees(address account) external onlyOwner {
        // Exempt from paying any fees 
        // i.e. will pay 0% fee for both project and reflection fees 
        _isExcludedFromFee[account] = true;
    }
    function C23_checkif_ExcludedFromPayingFees(address account) external view returns(bool) {
        // True  - Is exempted from paying any fees 
        //         i.e. pays 0% fee for both project and reflection fees
        // False - Is charged all fees 
        //         i.e. pays both project and reflections fees
        return _isExcludedFromFee[account];
    }
    function C24_checkif_excluded_fromReceiving_Reflections(address account) external view returns (bool) {
        // True  - Account doesn't receive reflections 
        // False - Account receives reflections
        return _isExcludedRewards[account];
    }
    function C25_enable_receive_Reflections(address account) external onlyOwner {
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
    function C26_exclude_fromReceiving_Reflections(address account) external onlyOwner {
        // Will not receive reflections
        require(!_isExcludedRewards[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedRewards[account] = true;
        _excluded.push(account);
    }   

    // Project fee further split to wallets

    function D1_set_FondoBNB_wallet(address account) external onlyOwner {
        FondoBNB_wallet = account;
    }
    function D2_set_ReservaTokens_wallet(address account) external onlyOwner {
        ReservaTokens_wallet = account;
    }
    function D3_set_BlockchainSupport_wallet(address account) external onlyBlockchainDev {
        BlockchainSupport_wallet = account;
    }

    // Blockchain Support Team members

    function E1_add_BlockchainSupportDev(address account) external onlyBlockchainDev {
        require(!BlockchainSupportDevs[account],"Blockchain Support Dev already added");
        BlockchainSupportDevs[account] = true;
        emit Added_BlockchainSupportDev(account);
    }
    function E2_remove_BlockchainSupportDev(address account) external onlyBlockchainDev {
        require(BlockchainSupportDevs[account],"Unable to remove. The account is not in the BlockchainSupportDevs list");
        BlockchainSupportDevs[account] = false;
        emit Removed_BlockchainSupportDev(account);
    }
    function E3_check_BlockchainSupportDev(address account) external view returns (bool) {   
        return BlockchainSupportDevs[account];
    }

    // Bridges and Exchanges 

    function F1_add_BridgeOrExchange(address account, uint256 proj_fee, uint256 reflections_fee) external onlyOwner {
        BridgeOrExchange[account] = true;
        BridgeOrExchange_ProjectFee[account] = proj_fee;
        BridgeOrExchange_ReflectionsFee[account] = reflections_fee;
    }
    function F2_remove_BridgeOrExchange(address account) external onlyOwner {
        delete BridgeOrExchange[account];
        delete BridgeOrExchange_ProjectFee[account];
        delete BridgeOrExchange_ReflectionsFee[account];
    }
    function F3_check_BridgeOrExchange(address account) external view returns (bool) {
        return BridgeOrExchange[account];
    }
    function F4_get_BridgeOrExchange_ProjectFee(address account) external view returns (uint256) {
        return BridgeOrExchange_ProjectFee[account];
    }
    function F5_get_BridgeOrExchange_ReflectionsFee(address account) external view returns (uint256) {
        return BridgeOrExchange_ReflectionsFee[account];
    }
     //To recieve BNB from PancakeSwap V2 Router when swaping
    receive() external payable {}
}