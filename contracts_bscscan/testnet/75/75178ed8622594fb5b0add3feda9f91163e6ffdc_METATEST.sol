/**
 *Submitted for verification at BscScan.com on 2022-01-17
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
    address internal _owner;
    address internal _previousOwner;

    event Owner_Changed_by_Owner(address indexed previousOwner, address indexed newOwner);
    event Owner_Changed_by_Security_Manager(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit Owner_Changed_by_Owner(address(0), msgSender);
    }
     
    address public Security_Manager = _msgSender(); // change it upon contract deploy to complete owners separation   

    event Changed_Security_Manager(address indexed previous_Security_Manager, address indexed new_Security_Manager);

    address internal previous_Security_Manager;
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || Security_Manager == _msgSender(), "Aborted. You are not Owner");
        _;
    }
    
    // Modifier used only for changing the
    // contract ownership by the main owner:

    modifier onlyTheOwner() {
        require(_owner == _msgSender(), "Aborted. You are not main Owner");
        _;
    }

    modifier onlySecurityManager() {
        require(Security_Manager == _msgSender(), "You are not Security Manager");
        _;
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

    mapping (address => bool) private isExcludedFromFees; // exempt from paying any fees
    mapping (address => bool) private isExcludedReflections; // exempt from receiving reflections
    address[] private _excluded;

    uint8 private _decimals = 7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 5000000 * 10**_decimals; // 500 Million
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "META TEST";
    string private _symbol = "META35";

    // Sell price impact tiers 
    //   (% multiplied by 100)
    uint256 public price_impact1;
    uint256 public price_impact2;

    // Fees for buy trades (%)
    uint256 public Buy_TotalProjectFee;
    uint256 public Buy_ReflectionsFee;

    // Fees for sell trades (%)
    uint256 public Sell_Default_Total_ProjectFee; 
    uint256 public Sell_Default_ReflectionsFee;
    
    uint256 public Sell_Total_ProjectFee_Under_Impact1;
    uint256 public Sell_Total_ProjectFee_Above_Impact1;
    uint256 public Sell_Total_ProjectFee_Above_Impact2;
    
    uint256 public Sell_ReflectionsFee_Under_Impact1;
    uint256 public Sell_ReflectionsFee_Above_Impact1;
    uint256 public Sell_ReflectionsFee_Above_Impact2;

    // Fees for normal transfers (%)
    uint256 public transfer_TotalProjectFee;
    uint256 public transfer_ReflectionsFee;

    // Internal. Takes the value of buy
    // sell and transfer fees, respectively
    uint256 private totalProjectFee;
    uint256 private reflectionsFee;

    uint256 private previous_totalProjectFee;
    uint256 private previous_ReflectionsFee;   

    // Total Project funding fee split 
    // into portions (%) (total must be 100%) 
    uint256 public productDevelopmentFee; 
    uint256 public marketingFee;          
    uint256 public blockchainSupportFee;  
    uint256 public reservaFee;

    // Waiting time between sells (in seconds)
    bool private Impact2_Must_Wait_Longer_Before_Next_Sell;
    mapping(address => uint256) private sell_AllowedTime;

    uint256 public normal_waiting_time_between_sells;
    uint256 public waiting_time_to_sell_after_impact2;                             
    
    address public productDevelopmentWallet;
    address public marketingWallet;
    address public blockchainSupportWallet;
    address public reservaWallet;
    address public communityWallet;       

    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_TotalProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;

    // Marketing Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Marketing funds and wallet 
    mapping(address => bool) private Marketing_Manager;    

    // Blockchain Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Blockchain Support funds and wallet 
    mapping(address => bool) private Blockchain_Manager; 

    bool public Public_Trading_Enabled;
    bool private is_Buy_Trade;
    bool private is_Sell_Trade;

    bool private Project_Funding_Swap_Mode;    
    uint256 public minAmountTokens_ProjectFundingSwap =  10 * 10**_decimals; // 0.0002%

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    event Project_Funding_Done(
        uint256 tokensSwapped,
		uint256 amountBNB
    );
    event Transfer_Fee_Tokens_Sent_To_Community_Wallet(
		address indexed recipient,
		uint256 amount
	);
    event Impact2_Caused_Account_Must_Wait_Longer_Before_Next_Sell(
        address indexed account, 
        uint256 next_time_can_sell
    );

    event Added_Blockchain_Manager(address indexed account);
    event Removed_Blockchain_Manager(address indexed account);

    event Added_Marketing_Manager(address indexed account);
    event Removed_Marketing_Manager(address indexed account);

    modifier lockTheSwap {
        Project_Funding_Swap_Mode = true;
        _;
        Project_Funding_Swap_Mode = false;
    }
    modifier onlyMarketingManager() {
       require(Marketing_Manager[msg.sender], "You are not a Marketing Manager");
        _;
    }
    modifier onlyBlockchainManager() {
       require(Blockchain_Manager[msg.sender], "You are not a Blockchain Manager");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // PancakeSwap V2 Router
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        
        // For testing in BSC Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); 

        // Create a pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // Set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // Exclude owners and this contract from all fees
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[Security_Manager] = true;
        isExcludedFromFees[address(this)] = true;

        productDevelopmentWallet = msg.sender;
        marketingWallet = msg.sender;
        blockchainSupportWallet = msg.sender;
        reservaWallet = msg.sender;
        communityWallet = msg.sender;
        
        Marketing_Manager[msg.sender] = true;
        Blockchain_Manager[msg.sender] = true;
        
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
        if (isExcludedReflections[account]) return _tOwned[account];
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
    //
    // Disabled, as it is not useful. And also to 
    // minimize confusion with the Total Project Fee
    //
    //function totalFees() public view returns (uint256) {
    //    return _tFeeTotal;
    //}
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
        require(Public_Trading_Enabled || isExcludedFromFees[from] || isExcludedFromFees[to], "Public Trading has not been enabled yet.");
        
        if (from != owner() && to != owner() && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                totalProjectFee = Buy_TotalProjectFee; 
                reflectionsFee  = Buy_ReflectionsFee;
                is_Buy_Trade = true;

            } else if (to == uniswapV2Pair && from != uniswapV2Pair ) {
                     if (normal_waiting_time_between_sells > 0 || waiting_time_to_sell_after_impact2 > 0) {
                        require(block.timestamp > sell_AllowedTime[from]);
                      }

                     if (price_impact1 != 0){
                    
                         if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact1)) {
                             totalProjectFee = Sell_Total_ProjectFee_Under_Impact1;
                             reflectionsFee  = Sell_ReflectionsFee_Under_Impact1;

                          } else if (price_impact2 == 0){
                             totalProjectFee = Sell_Total_ProjectFee_Above_Impact1;
                             reflectionsFee  = Sell_ReflectionsFee_Above_Impact1;

                          } else if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact2 )) {
                             totalProjectFee = Sell_Total_ProjectFee_Above_Impact1;
                             reflectionsFee  = Sell_ReflectionsFee_Above_Impact1;

                          } else {
                             totalProjectFee = Sell_Total_ProjectFee_Above_Impact2;
                             reflectionsFee  = Sell_ReflectionsFee_Above_Impact2;

                             // If the longer waiting time setting is set to non zero   
                             // then the contract will use the longer waiting feature   
                             if (waiting_time_to_sell_after_impact2 > 0) {
                                Impact2_Must_Wait_Longer_Before_Next_Sell = true;
                             }
                         }

                     } else {
                         // If price impact1 is zero then the price impacts   
                         // feature is disabled. And default fees are used.   
                            totalProjectFee = Sell_Default_Total_ProjectFee;
                            reflectionsFee  = Sell_Default_ReflectionsFee;
                }

                is_Sell_Trade = true;

            } else if (from != uniswapV2Pair && to != uniswapV2Pair) {

                if (BridgeOrExchange[from]) {
                        totalProjectFee = BridgeOrExchange_TotalProjectFee[from];
                        reflectionsFee  = BridgeOrExchange_ReflectionsFee[from];
                }
                else if (BridgeOrExchange[to]) {
                        totalProjectFee = BridgeOrExchange_TotalProjectFee[to];
                        reflectionsFee  = BridgeOrExchange_ReflectionsFee[to];
                }
                else {
                        totalProjectFee = transfer_TotalProjectFee; 
                        reflectionsFee  = transfer_ReflectionsFee;

                        // To prevent evading the sell waiting time by sending tokens 
                        // to another wallet and then selling from that other wallet 
                        // we set the (same) sell waiting time also for the other wallet.
                        if (normal_waiting_time_between_sells > 0 || waiting_time_to_sell_after_impact2 > 0)  {
                           sell_AllowedTime[to] = sell_AllowedTime[from];
                        }
                }
                // Resetting these to make sure that _takeProjectFee works as  
                // intended if previous transaction was a buy or a sell trade
                is_Sell_Trade = false;
                is_Buy_Trade = false;
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        // ProjectFundingSwap i.e. selling done by the token contract 
        // is purposely set not be executed during a buy trade. We have
        // observed that if/when the contract sells immediately after 
        // a buy trade it may look like there is a bot that is constantly
        // selling on people buys.    
        bool overMinTokenBalance = contractTokenBalance >= minAmountTokens_ProjectFundingSwap;
        if (
            overMinTokenBalance &&
            !Project_Funding_Swap_Mode && 
            from != uniswapV2Pair 
        ) {
            projectFundingSwap(contractTokenBalance);
        }        

        bool takeAllFees = true;
        
        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeAllFees = false;
        }        
        _tokenTransfer(from,to,amount,takeAllFees);
        restoreAllFees;

        if (is_Sell_Trade && Impact2_Must_Wait_Longer_Before_Next_Sell) {            
                sell_AllowedTime[from] = block.timestamp + waiting_time_to_sell_after_impact2;
                emit Impact2_Caused_Account_Must_Wait_Longer_Before_Next_Sell(from, sell_AllowedTime[from]);
                Impact2_Must_Wait_Longer_Before_Next_Sell = false;
        }
        else if (is_Sell_Trade && normal_waiting_time_between_sells > 0 ) {
                sell_AllowedTime[from] = block.timestamp + normal_waiting_time_between_sells;
        }
    }

    function projectFundingSwap(uint256 contractTokenBalance) private lockTheSwap {
        
        // check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        // calculate the percentages
        uint256 productDevelopmentBNB = BalanceBNB.div(100).mul(productDevelopmentFee);
        uint256 marketingBNB = BalanceBNB.div(100).mul(marketingFee);
        uint256 blockchainSupportBNB = BalanceBNB.div(100).mul(blockchainSupportFee);
        uint256 reservaBNB = BalanceBNB.div(100).mul(reservaFee);     

       // Send BNB to fund Product Development
        payable(productDevelopmentWallet).transfer(productDevelopmentBNB);

        // Send BNB to fund Marketing
        payable(marketingWallet).transfer(marketingBNB);

        // Send BNB to fund Blockchain products and Support
        payable(blockchainSupportWallet).transfer(blockchainSupportBNB); 

        // Send BNB to the Reserva wallet 
        payable(reservaWallet).transfer(reservaBNB); 

        emit Project_Funding_Done(tokensbeforeSwap, BalanceBNB);  
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
        
        if (isExcludedReflections[sender] && !isExcludedReflections[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!isExcludedReflections[sender] && isExcludedReflections[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!isExcludedReflections[sender] && !isExcludedReflections[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (isExcludedReflections[sender] && isExcludedReflections[recipient]) {
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
        if (is_Buy_Trade || is_Sell_Trade) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(isExcludedReflections[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        } else {
            _rOwned[address(communityWallet)] = _rOwned[address(communityWallet)].add(rLiquidity);
            emit Transfer_Fee_Tokens_Sent_To_Community_Wallet(communityWallet, rLiquidity);

            if(isExcludedReflections[address(communityWallet)])
            _tOwned[address(communityWallet)] = _tOwned[address(communityWallet)].add(tLiquidity); 
            emit Transfer_Fee_Tokens_Sent_To_Community_Wallet(communityWallet, tLiquidity);
        }
    }
    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(reflectionsFee).div(100);
    }    
    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(totalProjectFee).div(100);
    }    
    function removeAllFees() private {
        if(reflectionsFee == 0 && totalProjectFee == 0) return;
        
        previous_ReflectionsFee = reflectionsFee;
        previous_totalProjectFee = totalProjectFee;
        
        reflectionsFee = 0;
        totalProjectFee = 0;
    }    
    function restoreAllFees() private {
        reflectionsFee = previous_ReflectionsFee;
        totalProjectFee = previous_totalProjectFee;
    }

    //To enable receiving BNB from PancakeSwap V2 Router when swapping
    receive() external payable {}   


    //**************  Security functions  *****************//

	function F01_Security_Check_Account(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    function F02_Blacklist_Malicious_Account(address account) external onlyOwner {
        require(!isBlacklisted[account], "Address is already blacklisted");
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted"); 
        require(account != address(this), "Token contract cannot be blacklisted"); 
        require(account != address(0), "Zero address cannot be blacklisted");
     	require(account != owner(), "Owner account cannot be blacklisted");
        require(account != Security_Manager, "Security Manager account cannot be blacklisted");
        require(!Marketing_Manager[account], "Marketing Manager account cannot be blacklisted");
        require(!Blockchain_Manager[account], "Blockchain Manager account cannot be blacklisted");
        require(account != marketingWallet, "Marketing wallet cannot be blacklisted");	
        require(account != blockchainSupportWallet, "Blockchain Support wallet cannot be blacklisted");
 			
        isBlacklisted[account] = true;
    }
    function F03_Whitelist_Account(address account) external onlyOwner {
        require(isBlacklisted[account], "Address is already whitelisted");

        isBlacklisted[account] = false;
    }

    //************  Enable or Disable Trading  ***************//
    
    function F04_Enable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = true;
    }
    function F05_Disable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = false;
    }

    //*************  Waiting times for sells  ***************//

    function F06_Check_When_Account_Can_Sell_Again(address account) external view returns (string memory, uint256) {
        // If the parameter "normal_waiting_time_between_sells" or 
        // "waiting_time_to_sell_after_impact2" is non zero 
        // then the waiting time between sells feature is enabled. 
        // Then this function can be used then to check when is the
        // earliest time an account can sell again.
        require (balanceOf(account) > 0, "Account has no tokens");  

        string memory Message;

        if ( block.timestamp >= sell_AllowedTime[account]) {
                Message = " Good news !"
                          " The account can do next sell at any time."
                          " Below is the registered time (in Unix format)"
                          " after which the account can do a sell trade."; 
        } else {
                Message = " Be patient please." 
                          " The account cannot sell until the time shown below."
                          " The time is in Unix format. Use free online time conversion"
                          " websites/services to convert to common Date and Time format";
        }
        return (Message, sell_AllowedTime[account]);
    }
    function F07_Shorten_Account_Waiting_Time_Before_Next_Sell(address account, uint256 unix_time) external onlyOwner {
        // Tips:
        //      To allow selling with no more waiting set --> unix_time = 0
        //
        //      And use free only time conversion website/services
        //      to convert the new allowed date and time to Unix time.
        require (sell_AllowedTime[account] > block.timestamp, "Aborted. The account can already sell at any time"); 
        require (unix_time < sell_AllowedTime[account], "Aborted. The time must be earlier than currently allowed time");

        sell_AllowedTime[account] = unix_time;
    }
    function F08_Set_Normal_Waiting_Time_Between_Sells(uint256 wait_seconds) external onlyOwner {
        // Examples: 
        // To have a 60 seconds wait --> wait_seconds = 60
        //
        // To disable this feature i.e. to have no waiting
        // time then set this to zero --> wait_seconds = 0
        normal_waiting_time_between_sells = wait_seconds;
    }
    function F09_Set_Waiting_Time_For_Next_Sell_After_Impact2(uint256 wait_seconds) external onlyOwner {
        require (price_impact2 > 0, "Aborted. The longer waiting time cannot be used while price_impact2 is 0");            
        //Examples:   Must wait 3 days --> wait_seconds = 259200
        //                      7 days --> wait_seconds = 604800
        //
        // To disable the (usually longer) waiting time after
        // a sell with price impact2 then set this to zero --> wait_seconds = 0
        // 
        // And if the normal waiting time is enabled (is non zero) 
        // then it will be used for all sells with price impact2. 
        waiting_time_to_sell_after_impact2 = wait_seconds;
    }

    //*************  Price impacts feature  ****************//

    function F10_Set_Sell_Price_Impact1__Multiplied_by_100(uint256 Price_impact1) external onlyOwner {
        require (Price_impact1 < price_impact2 || price_impact2 == 0, "Aborted. Price impact1 must be less than price impact2");
        // To support a percentage number with a decimal
        // the percentage is / must be multiplied by 100.
        //
        // Examples:  1% price impact --> Price_impact1 = 100
        //          0.5% price impact --> Price_impact1 =  50
        //
        // To disable both price impacts tiers
        //  i.e. the price impacts feature --> Price_impact1 = 0  
        price_impact1 = Price_impact1;
    }
    function F11_Set_Sell_Price_Impact2__Multiplied_by_100(uint256 Price_impact2) external onlyOwner {
        require (Price_impact2 > price_impact1, "Aborted. Price impact2 must be larger than price impact1"); 
        // Attention: Setting the price impact2 value is not enough. 
        //            To enable it / for it to be used price impact1
        //            must be (set to) non zero. 
        //
        // Examples:  20% price impact --> Price_impact2 = 2000
        //            30% price impact --> Price_impact2 = 3000
        //
        // To disable the price impact2 tier --> Price_impact2 = 0
        price_impact2 = Price_impact2;
        if (Price_impact2 == 0){waiting_time_to_sell_after_impact2 = 0;}
    }

    //***************  Total Project Fees  *****************//

    function F12_Set_Total_Project_Fee_For_Transfers(uint256 fee_percent) external onlyOwner {
        // Set project fee for transfers from wallet to wallet
        transfer_TotalProjectFee = fee_percent;
    }
    function F13_Set_Total_Project_Fee_For_Buys(uint256 fee_percent) external onlyOwner {
        Buy_TotalProjectFee = fee_percent;
    }
    function F14_Set_Total_Project_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external onlyOwner {
        // Set project fee up to price impact
        Sell_Total_ProjectFee_Under_Impact1 = fee_percent;
    }
    function F15_Set_Total_Project_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external onlyOwner {
        // If you need only one fee (a flat fee) then set this fee 
        // to same value as for Sell_Total_ProjectFee_Under_Impact1
        // or set in F10 the price impact1 to 100% i.e. Price_Impact1 = 10000    
        Sell_Total_ProjectFee_Above_Impact1 = fee_percent;
    }
    function F16_Set_Total_Project_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external onlyOwner {
        // If you need only one fee (a flat fee) then set this fee 
        // to same value as for Sell_Total_ProjectFee_Under_Impact1
        // or set in F10 the price impact1 to 100% i.e. Price_Impact1 = 10000    
        Sell_Total_ProjectFee_Above_Impact2 = fee_percent;
    }
    function F17_Set_Default_Total_Project_Fee_For_Sells(uint256 fee_percent) external onlyOwner {
        // The default Total Project fee for sells is 
        // used if price impact1 is zero. I.e. when the 
        // price impacts feature is not used / is disabled.
        Sell_Default_Total_ProjectFee = fee_percent;
    }
        
    //************  Reflection fees  ***************//
    
    function F18_Set_Reflections_Fee_For_Transfers(uint256 fee_percent) external onlyOwner {
        // Set reflections fee for transfers from wallet to wallet
        transfer_ReflectionsFee = fee_percent;
    }
    function F19_Set_Reflections_Fee_for_Buys(uint256 fee_percent) external onlyOwner {
        Buy_ReflectionsFee = fee_percent;
    }    
    function F20_Set_Reflections_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external onlyOwner {
        // Set reflection fee for sells up to price impact
        Sell_ReflectionsFee_Under_Impact1 = fee_percent;
    }
    function F21_Set_Reflections_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external onlyOwner {
        // Set total project fee for sells above price impact1 
        Sell_ReflectionsFee_Above_Impact1 = fee_percent;
    }
    function F22_Set_Reflections_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external onlyOwner {
        // Set total project fee for sells above price impact2 
        Sell_ReflectionsFee_Above_Impact2 = fee_percent;
    }
    function F23_Set_Default_Reflections_Fee_For_Sells(uint256 fee_percent) external onlyOwner {
        // The default Reflections fee for sells is used 
        // if price impact1 is zero. I.e. when the price 
        // impacts feature is not used / is disabled.
        Sell_Default_ReflectionsFee = fee_percent;
    }

    //************  Total Project fee split in portions  **************// 
  
    function F24_Set_Product_Development_Fee_Portion(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + marketingFee + blockchainSupportFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the sum of all fees portions must be less or equal 100");
        productDevelopmentFee = fee_percent;
    }
    function F25_Set_Marketing_Fee_Portion(uint256 fee_percent) external onlyMarketingManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + blockchainSupportFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the sum of all fees portions must be less or equal 100");
        marketingFee = fee_percent;
    }
    function F26_Set_BlockchainSupport_Fee_Portion(uint256 fee_percent) external onlyBlockchainManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + marketingFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the sum of all fees portions must be less or equal 100");   
        blockchainSupportFee = fee_percent;
    }
    function F27_Set_Reserva_Fee_Portion(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !   
        
        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + marketingFee + blockchainSupportFee;        
        require(New_Total_Fee <= 100, "Aborted. When updating the sum of all fees portions must be less or equal 100");
        reservaFee = fee_percent;
    }

     //****************************************************************//
     //               Must pay fees / exclude from fees                //
     //         Receive reflections / exclude from reflections         //
     //****************************************************************// 

    function F28_Enable_Account_Must_Pay_Fees(address account) external onlyOwner {
        // Enable will be charged all fees
        // i.e. will pay both project and reflections fees
        isExcludedFromFees[account] = false;
    }
    function F29_Exclude_Account_from_Paying_Fees(address account) external onlyOwner {
        // Exempt from paying any fees 
        // i.e. will pay 0% fee for both project and reflection fees 
        isExcludedFromFees[account] = true;
    }
    function F30_Check_if_Account_is_Excluded_from_Paying_Fees(address account) external view returns(bool) {
        // True  - Is exempted from paying any fees 
        //         i.e. pays 0% fee for both project and reflection fees
        // False - Is charged all fees 
        //         i.e. pays both project and reflections fees
        return isExcludedFromFees[account];
    }
    function F31_check_if_Account_is_Excluded_from_Receiving_Reflections(address account) external view returns (bool) {
        // True  - Account doesn't receive reflections 
        // False - Account receives reflections
        return isExcludedReflections[account];
    }
    function F32_Enable_Account_will_Receive_Reflections(address account) external onlyOwner {
        require(isExcludedReflections[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                isExcludedReflections[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function F33_Exclude_Account_from_Receiving_Reflections(address account) external onlyOwner {
        // Will not receive reflections
        require(!isExcludedReflections[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isExcludedReflections[account] = true;
            _excluded.push(account);
    }   

    //****************  Project wallets  ******************//

    function F34_Set_Product_Development_Wallet(address account) external onlyOwner {
        productDevelopmentWallet = account;
    }
    function F35_Set_Marketing_Wallet(address account) external onlyMarketingManager {
        marketingWallet = account;
    }
    function F36_Set_Blockchain_Support_Wallet(address account) external onlyBlockchainManager {
        blockchainSupportWallet = account;
    }
    function F37_Set_Reserva_Wallet(address account) external onlyOwner {
        reservaWallet = account;
    }
    function F38_Set_Community_Wallet(address account) external onlyOwner {
        communityWallet = account;
    }

    //************  Marketing Manager account  *************//

    function F39_Add_Marketing_Manager(address account) external onlyMarketingManager {
        require(!Marketing_Manager[account],"Marketing Manager already added");
        Marketing_Manager[account] = true;
        emit Added_Marketing_Manager(account);
    }
    function F40_Remove_Marketing_Manager(address account) external onlyMarketingManager {
        require(Marketing_Manager[account],"The account is not in Marketing Manager account");
        Marketing_Manager[account] = false;
        emit Removed_Marketing_Manager(account);
    }
    function F41_Check_is_Marketing_Manager(address account) external view returns (bool) {   
        return Marketing_Manager[account];
    }

    //*************  Blockchain Manager account  **************//

    function F42_Add_Blockchain_Manager(address account) external onlyBlockchainManager {
        require(!Blockchain_Manager[account],"Blockchain Manager already added");
        Blockchain_Manager[account] = true;
        emit Added_Blockchain_Manager(account);
    }
    function F43_Remove_Blockchain_Manager(address account) external onlyBlockchainManager {
        require(Blockchain_Manager[account],"The account is not in a Blockchain Manager account");
        Blockchain_Manager[account] = false;
        emit Removed_Blockchain_Manager(account);
    }
    function F44_Check_is_Blockchain_Manager(address account) external view returns (bool) {   
        return Blockchain_Manager[account];
    }

    //***************  Bridges and Exchanges  ****************// 

    function F45_Add_Bridge_Or_Exchange(address account, uint256 proj_fee, uint256 reflections_fee) external onlyOwner {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap is not allowed"); 
        require(account != address(this), "Token contract is not allowed"); 
        require(account != address(0), "Zero address is not allowed");    
     	require(account != owner(), "Owner account is not allowed");
        require(account != Security_Manager, "Security Manager account is not allowed");
        require(!Marketing_Manager[account], "Marketing Manager account is not allowed");
        require(!Blockchain_Manager[account], "Blockchain Manager account is not allowed");
        require(account != marketingWallet, "Marketing wallet is not allowed");	
        require(account != blockchainSupportWallet, "Blockchain Support wallet is not allowed");

        BridgeOrExchange[account] = true;
        BridgeOrExchange_TotalProjectFee[account] = proj_fee;
        BridgeOrExchange_ReflectionsFee[account] = reflections_fee;
    }
    function F46_Remove_Bridge_Or_Exchange(address account) external onlyOwner {
        delete BridgeOrExchange[account];
        delete BridgeOrExchange_TotalProjectFee[account];
        delete BridgeOrExchange_ReflectionsFee[account];
    }
    function F47_Check_is_Bridge_Or_Exchange(address account) external view returns (bool) {
        return BridgeOrExchange[account];
    }
    function F48_Get_Bridge_Or_Exchange_Total_Project_Fee(address account) external view returns (uint256) {
        return BridgeOrExchange_TotalProjectFee[account];
    }
    function F49_Get_Bridge_Or_Exchange_Reflections_Fee(address account) external view returns (uint256) {
        return BridgeOrExchange_ReflectionsFee[account];
    }

    //****************  Miscellaneous  ****************//

    function F50_Set_Min_Amount_Tokens_for_ProjectFundingSwap(uint256 amount) external onlyOwner {
        // Example: 10 tokens --> minTokenAmount = 100000000 (i.e. 10 * 10**7 decimals) = 0.0002%
        minAmountTokens_ProjectFundingSwap = amount;
    }
    function F51_Rescue_Other_Tokens_Sent_To_This_Contract(IERC20 token, address receiver, uint256 amount) external onlyOwner {
        // This is a very appreciated feature !
        // I.e. to be able to send back to a user other BEP20 
        // tokens that the user have sent to this contract by mistake.   
        require(token != IERC20(address(this)), "Only other tokens can be rescued");
        require(receiver != address(this), "Recipient can't be this contract");
        require(receiver != address(0), "Recipient can't be the zero address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(receiver, amount);
    }

    //****************  Owner and Security Manager  ****************//
    //
    // - The Security Manager account is a second Owner account.
    //   It should be used only if/when the main Owner account has been
    //   compromised, e.g. due to a security incident that has occured.  
    //
    // - The Security Manager is more powerful than the Owner in this way:
    //   
    //    Security Manager can do everything that the Owner can do.
    //    The Owner can do everything the Security Manager can do
    //    except one thing the Owner cannot do: 
    //
    //    Security Manager --->  Can change ----------> Security Manager
    //    Security Manager --->  Can change ----------> Owner
    //
    //   SECURITY RECOMMENDATIONS:
    //               Owner --->  Can change ----------> Owner
    //               Owner --->  Cannot (!) change ---> Security Manager 
    //
    //
    //
    // - For maximum security do NOT use the Security Manager account for trading. 
    // 
    // - Manage the contract using the Owner account. 
    //   And use the Security Manager account (only) when you cannot use the Owner account.


    function F52_Owner_Change_by_Owner(address newOwner) public virtual onlyTheOwner {
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        require(newOwner != address(this), "Aborted. The new owner can't be this contract"); 
        _previousOwner = _owner;
        _owner = newOwner;
        isExcludedFromFees[newOwner] = true;
        isExcludedFromFees[_previousOwner] = false;
        emit Owner_Changed_by_Owner(_previousOwner, newOwner);
    }
    function F53_Owner_Change_by_Security_Manager(address newOwner) public virtual onlySecurityManager {
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        require(newOwner != address(this), "Aborted. The new owner can't be this contract"); 
        _previousOwner = _owner;
        _owner = newOwner;
        isExcludedFromFees[newOwner] = true;
        isExcludedFromFees[_previousOwner] = false;
        emit Owner_Changed_by_Security_Manager(_previousOwner, newOwner);
    }
    function F54_Security_Manager_Change_by_Security_Manager(address New_Security_Manager)  public virtual onlySecurityManager {
        require(New_Security_Manager != address(0), "Aborted. The new Security Manager can't be the zero address");
        require(New_Security_Manager != address(this), "Aborted. The new Security Manager can't be this contract"); 
        previous_Security_Manager = Security_Manager;
        Security_Manager = New_Security_Manager;
        isExcludedFromFees[New_Security_Manager] = true;
        isExcludedFromFees[previous_Security_Manager] = false;
        emit Changed_Security_Manager(previous_Security_Manager, New_Security_Manager);
    }
}