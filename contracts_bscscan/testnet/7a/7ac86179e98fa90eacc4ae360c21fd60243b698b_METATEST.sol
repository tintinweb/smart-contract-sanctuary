/**
 *Submitted for verification at BscScan.com on 2022-01-06
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

    event Owner_Changed(address indexed previousOwner, address indexed newOwner);
    event Owner_Changed_by_Security_Manager(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit Owner_Changed(address(0), msgSender);
    }
    
    // SECURITY RECOMMENDATIONS:
    //
    // - The Security Manager account is like a second Owner account.
    //   It should be used only when the main Owner account can't be
    //   used anymore, e.g. due to a security incident.  
    //
    // - Security Manager is more powerful than the Owner in this way:
    //   
    //    Security Manager can do everything that the Owner can do.
    //    But there is one key difference, one thing that the Owner 
    //    can't do and only the Security Manager can do:
    //
    //    Only the Security Manager can set a new Security Manager.
    //    The Owner can't change the Security Manager.
    //    While the Security Manager can change the Owner
    //
    // - For maximum security do NOT use the Security Manager account for trading. 
    // 
    // - Make sure to save the Security Manager wallet (account) private key <-- VERY IMPORTANT !!! 
    //   And also the passphrase. Then keep them both in a 
    //   very secure place e.g. in a bank safe deposit box.
    //
 
    address public Security_Manager = _msgSender(); // change it upon contract deploy to complete owners separation   

    event Changed_Security_Manager(address indexed previous_Security_Manager, address indexed new_Security_Manager);

    address private previous_Security_Manager;

    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender() || Security_Manager == _msgSender(), "Aborted. You are not Owner");
        _;
    }
    modifier onlySecurityManager() {
        require(Security_Manager == _msgSender(), "You are not Security Manager");
        _;
    }
    function Z1_Owner_Change(address newOwner) public virtual onlyOwner {
        // IMPORTANT: 
        // Usually one needs also to execute F29_Enable_Must_Pay_Fees function
        // if the old Owner will not be excluded anymore from paying fees
        // And also run F30_Exclude_from_Paying_Fees for the new Owner 
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit Owner_Changed(_previousOwner, newOwner);
    }
    function Z2_Owner_Change_by_Security_Manager(address newOwner) public virtual onlySecurityManager {
        // IMPORTANT: 
        // Usually one needs also to execute F29_Enable_Must_Pay_Fees function
        // if the old Owner will not be excluded anymore from paying fees
        // And also run F30_Exclude_from_Paying_Fees for the new Owner  
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit Owner_Changed_by_Security_Manager(_previousOwner, newOwner);

    }
    function Z3_Change_Security_Manager(address newSecurityManager)  public virtual onlySecurityManager {
        // IMPORTANT: 
        // Usually one needs also to execute F29_Enable_Must_Pay_Fees function
        // if the old Security Manager will not be excluded anymore from paying fees
        // And also run F30_Exclude_from_Paying_Fees for the new Security Manager  
        require(newSecurityManager != address(0), "Aborted. The new Security Manager can't be the zero address");
        previous_Security_Manager = Security_Manager;
        Security_Manager = newSecurityManager;
        emit Changed_Security_Manager(previous_Security_Manager, newSecurityManager);
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
    uint256 private _tTotal = 5000000 * 10**_decimals; // 500 Million
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "META TEST";
    string private _symbol = "META_41";
   
    address public _marketingWallet;
    address public _productDevelopmentWallet;
    address public _blockchainSupportWallet;
    address public _reservaWallet;
    address public _communityWallet;

    uint256 public price_impact1 = 1000;  // 10%  (1% price impact = 100)
    
    // Price impact2 has not an own fee. The fee is same as for impact1.
    // It adds instead a longer wating time before one can sell again.  
    uint256 public price_impact2_has_longer_waiting = 2000; // 20%  
    uint256 public antiDump_longer_sell_waiting_time_seconds = 604800; // 7 days in seconds                              
    // All fees are a percentage number

    // Total Project funding fee
    uint256 public  totalProjectFee = 1; // can be overriden in sell and buy functions
    uint256 private previousProjectFee;
 
    // Project funding fee split 
    // Important: 
    // productDevelopmentFee + marketingFee + blockchainSupportFee + reservaFee = 100 <-- Mandatory rule !
    //
    uint256 public productDevelopmentFee = 25; // Percentage (portion) of total Project fee
    uint256 public marketingFee = 25;          // Percentage (portion) of total Project fee
    uint256 public blockchainSupportFee = 25;  // Percentage (portion) of total Project fee
    uint256 public reservaFee = 25;            // Percentage (portion) of total Project fee

    // Reflections - free tokens distribution
    //               to holders (passive income)
    uint256 public  reflectionsFee = 1; // this may change in sell and buy functions
    uint256 private previousReflectionsFee;

    uint256 public transfer_TotalProjectFee = 1;
    uint256 public transfer_ReflectionsFee = 0;

    uint256 public buy_TotalProjectFee = 1;
    uint256 public buy_ReflectionsFee = 0;

    uint256 public sell_TotalProjectFee_A = 1; // Lowest fee up to price impact
    uint256 public sell_TotalProjectFee_B = 30; // Higher fee above price impact (to disable set it same as A)
          
    uint256 public sell_ReflectionsFee_A = 1; // Up to price impact
    uint256 public sell_ReflectionsFee_B = 3; // Above price impact
  
    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_TotalProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;

    // Blockchain Support Manager. 
    // Has no control of the smart contract except do this:  
    // Can only change the Blockchain Support wallet to auto charge for provided services 
    mapping(address => bool) private Blockchain_Support_Manager; 

    // Marketing Manager. 
    // Has no control of the smart contract except do this:  
    // Can only change the Marketing wallet to auto fill funds for Marketing 
    mapping(address => bool) private Marketing_Manager; 

    mapping(address => uint256) private sell_AllowedTime;
    bool public antiDump_Sell_Waiting_Enabled = false;
    uint256 public antiDump_normal_sell_waiting_time_seconds = 60;
                
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public  AllFeesEnabled = true;
    bool private is_Buy_Trade;
    bool private is_Sell_Trade;
    
    bool private ProjectFundingSwapMode;
    bool public Public_Trading_Enabled = false;

    uint256 public minAmountTokens_ProjectFundingSwap =  10 * 10**_decimals; // 0.0002%

    event ProjectFundingDone(
        uint256 tokensSwapped,
		uint256 amountBNB
    );
    event TokensSentToCommunityWallet (
		address indexed recipient,
		uint256 amount
	);
    event Added_Blockchain_Support_Manager(address indexed account);
    event Removed_Blockchain_Support_Manager(address indexed account);

    event Added_Marketing_Manager(address indexed account);
    event Removed_Marketing_Manager(address indexed account);

    modifier lockTheSwap {
        ProjectFundingSwapMode = true;
        _;
        ProjectFundingSwapMode = false;
    }
    modifier onlyMarketingManager() {
       require(Marketing_Manager[msg.sender], "You are not a Marketing Manager");
        _;
    }
    modifier onlyBlockchainManager() {
       require(Blockchain_Support_Manager[msg.sender], "You are not a Blockchain Support Manager");
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
        
        // Exclude owners and this contract from all fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[Security_Manager] = true;
        _isExcludedFromFee[address(this)] = true;

        _marketingWallet = msg.sender;
        _productDevelopmentWallet = msg.sender;
        _communityWallet = msg.sender;
        _blockchainSupportWallet = msg.sender;
        _reservaWallet = msg.sender;
        
        Marketing_Manager[msg.sender] = true;
        Blockchain_Support_Manager[msg.sender] = true;
        
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
                is_Buy_Trade = true;
                totalProjectFee = buy_TotalProjectFee; 
                reflectionsFee  = buy_ReflectionsFee;
            }
            if (to == uniswapV2Pair && from != uniswapV2Pair ) {

                is_Sell_Trade = true;

                if (antiDump_Sell_Waiting_Enabled) {
                    require(block.timestamp > sell_AllowedTime[from]);
                }
                if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact1)) {
                    totalProjectFee = sell_TotalProjectFee_A;
                    reflectionsFee  = sell_ReflectionsFee_A;

                } else {
                    totalProjectFee = sell_TotalProjectFee_B;
                    reflectionsFee  = sell_ReflectionsFee_B;
                }   
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {

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

                        if (antiDump_Sell_Waiting_Enabled) {
                           // To prevent evading the sell waiting time by sending to 
                           // another wallet and then selling from it we set same sell
                           // waiting time for the recipient wallet
                              sell_AllowedTime[to] = sell_AllowedTime[from];
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
        bool overMinTokenBalance = contractTokenBalance >= minAmountTokens_ProjectFundingSwap;
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

        if (antiDump_Sell_Waiting_Enabled && is_Sell_Trade ) {
            
            if (amount >= balanceOf(uniswapV2Pair).div(10000).mul(price_impact2_has_longer_waiting)) {

                   sell_AllowedTime[from] = block.timestamp + antiDump_longer_sell_waiting_time_seconds;
            }
            else {
                   sell_AllowedTime[from] = block.timestamp + antiDump_normal_sell_waiting_time_seconds;
            }
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

        //pay the Blockchain Support Team wallet
        payable(_blockchainSupportWallet).transfer(blockchainSupportBNB); 

       //pay the Product Development wallet
        payable(_productDevelopmentWallet).transfer(productDevelopmentBNB);

        //pay the Marketing wallet
        payable(_marketingWallet).transfer(marketingBNB);
        
        //pay the Reserva wallet
        payable(_reservaWallet).transfer(reservaBNB); 

        emit ProjectFundingDone(tokensbeforeSwap, BalanceBNB);  
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
        if (is_Buy_Trade || is_Sell_Trade) {
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
        return _amount.mul(totalProjectFee).div(100);
    }    
    function removeAllFees() private {
        if(reflectionsFee == 0 && totalProjectFee == 0) return;
        
        previousReflectionsFee = reflectionsFee;
        previousProjectFee = totalProjectFee;
        
        reflectionsFee = 0;
        totalProjectFee = 0;
    }    
    function restoreAllFees() private {
        reflectionsFee = previousReflectionsFee;
        totalProjectFee = previousProjectFee;
    }

    //To recieve BNB from PancakeSwap V2 Router when swapping
    receive() external payable {}   


    // Security functions

    function F01_Blacklist_Malicious_Account(address account) external onlyOwner {
        require(!isBlacklisted[account], "Address is already blacklisted");
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted"); 
        require(account != address(this), "Token contract cannot be blacklisted");     
     	require(account != owner(), "Owner account cannot be blacklisted");
        require(account != Security_Manager, "Security Manager account cannot be blacklisted");
        require(!Marketing_Manager[account], "Marketing Manager account cannot be blacklisted");
        require(!Blockchain_Support_Manager[account], "Blockchain Support Manager account cannot be blacklisted");
        require(account != _marketingWallet, "Marketing wallet cannot be blacklisted");	
        require(account != _blockchainSupportWallet, "Blockchain Support wallet cannot be blacklisted");
 			
        isBlacklisted[account] = true;
    }
    function F02_Whitelist_Account(address account) external onlyOwner {
        require(isBlacklisted[account], "Address is already whitelisted");

        isBlacklisted[account] = false;
    }
	function F03_Check_if_Blacklisted(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    
    // Anti-Dump sell waiting settings

    function F04_Check_Selling_AllowedTime(address account) external view returns (string memory, uint256) {
        // If AntiDump sell waiting time is enabled then this function can be
        // used to check when is the earliest time an account can sell again.
        require (balanceOf(account) > 0, "Account has no tokens"); 
        string memory Message = " The time format is Unix time"
                                " Tip: Use free online time conversion websites"
                                " to convert from Unix time to a date and time.";
        return (Message, sell_AllowedTime[account]);     
    }
    function F05_Enable_AntiDump_Sell_Waiting() external onlyOwner {
        //Make sure to set also the waiting duration with B4  
        antiDump_Sell_Waiting_Enabled = true;
    }    
    function F06_Disable_AntiDump_Sell_Waiting() external onlyOwner {
        // Remove the restriction on waiting time between sells
        antiDump_Sell_Waiting_Enabled = false;
    }
    function F07_Set_AntiDump_Normal_Waiting_Duration_Sell(uint256 wait_seconds) external onlyOwner {
        // Set a waiting time between sells in seconds 
        // For this to take effect it must also be enabled with B2 function. 
        antiDump_normal_sell_waiting_time_seconds = wait_seconds;
    }
    function F08_Set_Min_Amount_Tokens_for_ProjectFundingSwap(uint256 amount) external onlyOwner {
        // Example: 10 tokens --> minTokenAmount = 100000000 (i.e. 10 * 10**7 decimals) = 0.0002%
        minAmountTokens_ProjectFundingSwap = amount;
    }


    // Trading, price impact and fees

    function F09_Enable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = true;
    }
    function F10_Disable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = false;
    }
    function F11_Enable_All_Fees() external onlyOwner {
        // Enable project and reflections fees
        AllFeesEnabled = true;
    }
    function F12_Disable_All_Fees() external onlyOwner {
        // Disable project and reflections fees
        AllFeesEnabled = false;
    }
    function F13_Set_Sell_Price_Impact1(uint256 impact1) external onlyOwner {
        // Examples:  1% price impact --> impact = 100
        //          0.5% price impact --> impact =  50  
        price_impact1 = impact1;
    }
    function F14_Set_Sell_Price_Impact2_and_Longer_Waiting (uint256 price_impact2, uint256 wait_secs) external onlyOwner {
        // Set the price impact for which it will set a
        // longer waiting time before one can sell again
        // Examples:  20% price impact --> price_impact2 = 2000
        //            Must wait 3 days --> wait_secs = 259200
        //                      7 days --> wait_secs = 604800
        price_impact2_has_longer_waiting = price_impact2;
        antiDump_longer_sell_waiting_time_seconds = wait_secs;
    }

    function F15_Set_Total_Project_Funding_Fee(uint256 fee_percent) external onlyOwner {
        // Example: 10% fee --> fee_percent = 10 
        totalProjectFee = fee_percent;
        // Project fee is in turn split in smaller pieces 
        // Use functions F16, F17, F18 and F19 to split it further 
    }
    function F16_Set_Product_Development_Fee_Portion(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !    
        productDevelopmentFee = fee_percent;
    }
    
    //  If function F17 is disabled then the Marketing services are provided
    //  (or were initially provided) by a Partner or an external company. It is also 
    //  so to ensure the contractual agreement and for mutual trust and safety reasons.

    //  function F17_Set_Marketing_Fee_Portion(uint256 fee_percent) external onlyMarketingManager {
    //      Example: 25% of total Project Fee --> fee_percent = 25
    //      IMPORTANT: 
    //      ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !   
    //      marketingFee = fee_percent;
    //}

    //  If function F18 is disabled then the Blockchain Support services are provided
    //  (or were initially provided) by a Partner or an external company. It is also 
    //  so to ensure the contractual agreement and for mutual trust and safety reasons.

    //  function F18_Set_BlockchainSupport_Fee_Portion(uint256 fee_percent) external onlyBlochchainManager {
    //      Example: 25% of total Project Fee --> fee_percent = 25
    //      IMPORTANT: 
    //      ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !   
    //      blockchainSupportFee = fee_percent;
    //}

    function F19_Set_Reserva_Fee(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !   
        reservaFee = fee_percent;
    }
    function F20_Set_Buy_Total_Project_Fee(uint256 fee_percent) external onlyOwner {
        buy_TotalProjectFee = fee_percent;
    }
    function CF21_Set_Buy_Reflections_Fee(uint256 fee_percent) external onlyOwner {
        buy_ReflectionsFee = fee_percent;
    }
    function F22_Set_Default_Reflections_Fee(uint256 fee_percent) external onlyOwner {
        // This function is normally not used
        reflectionsFee = fee_percent;
    }
    function F23_Set_Transfer_Total_Project_Fee(uint256 fee_percent) external onlyOwner {
        // Set project fee for transfers from wallet to wallet
        transfer_TotalProjectFee = fee_percent;
    }
    function F24_Set_Transfer_Reflections_Fee(uint256 fee_percent) external onlyOwner {
        // Set reflections fee for transfers from wallet to wallet
        transfer_ReflectionsFee = fee_percent;
    }
    function F25_Set_Sell_Total_Project_Fee_A(uint256 fee_percent) external onlyOwner {
        // Set project fee up to price impact
        sell_TotalProjectFee_A = fee_percent;
    }
    function F26_Set_Sell_Total_Project_Fee_B(uint256 fee_percent) external onlyOwner {
        // Set project fee above price impact.
        // To disable this tier set this fee to same as sell_TotalProjectFee_A
        // or set in F13 the price impact to 100% i.e. set impact = 10000    
        sell_TotalProjectFee_B = fee_percent;
    }
    function F27_Set_Sell_Reflections_Fee_A(uint256 fee_percent) external onlyOwner {
        // Set reflection fee for sells up to price impact
        sell_ReflectionsFee_A = fee_percent;
    }
    function F28_Set_Sell_Reflections_Fee_B(uint256 fee_percent) external onlyOwner {
        // Set total project fee for sells above price impact 
        sell_ReflectionsFee_B = fee_percent;
    }
    function F29_Enable_Must_Pay_Fees(address account) external onlyOwner {
        // Enable will be charged all fees
        // i.e. will pay both project and reflections fees
        _isExcludedFromFee[account] = false;
    }
    function F30_Exclude_from_Paying_Fees(address account) external onlyOwner {
        // Exempt from paying any fees 
        // i.e. will pay 0% fee for both project and reflection fees 
        _isExcludedFromFee[account] = true;
    }
    function F31_Check_if_Excluded_from_Paying_Fees(address account) external view onlyOwner returns(bool) {
        // True  - Is exempted from paying any fees 
        //         i.e. pays 0% fee for both project and reflection fees
        // False - Is charged all fees 
        //         i.e. pays both project and reflections fees
        return _isExcludedFromFee[account];
    }
    function F32_checkif_Excluded_from_Receiving_Reflections(address account) external view onlyOwner returns (bool) {
        // True  - Account doesn't receive reflections 
        // False - Account receives reflections
        return _isExcludedRewards[account];
    }
    function F33_Enable_Receives_Reflections(address account) external onlyOwner {
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
    function F34_Exclude_from_Receiving_Reflections(address account) external onlyOwner {
        // Will not receive reflections
        require(!_isExcludedRewards[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedRewards[account] = true;
        _excluded.push(account);
    }   


    // Total Project fee further split

    function F35_Set_Product_Development_Wallet(address account) external onlyOwner {
        _productDevelopmentWallet = account;
    }
    function F36_Set_Marketing_Wallet(address account) external onlyMarketingManager {
        _marketingWallet = account;
    }
    function F37_Set_BlockchainSupport_Wallet(address account) external onlyBlockchainManager {
        _blockchainSupportWallet = account;
    }
    function F38_Set_Reserva_Wallet(address account) external onlyOwner {
        _reservaWallet = account;
    }
    function F39_Set_Community_Wallet(address account) external onlyOwner {
        _communityWallet = account;
    }


    // Marketing Manager account

    function F40_Add_Marketing_Manager(address account) external onlyMarketingManager {
        require(!Marketing_Manager[account],"Marketing Manager already added");
        Marketing_Manager[account] = true;
        emit Added_Marketing_Manager(account);
    }
    function F41_Remove_Marketing_Manager(address account) external onlyMarketingManager {
        require(Marketing_Manager[account],"The account is not in Marketing Manager account");
        Marketing_Manager[account] = false;
        emit Removed_Marketing_Manager(account);
    }
    function F42_Check_if_Marketing_Manager(address account) external view returns (bool) {   
        return Marketing_Manager[account];
    }


    // Blockchain Support Manager account

    function F43_Add_Blockchain_Support_Manager(address account) external onlyBlockchainManager {
        require(!Blockchain_Support_Manager[account],"Blockchain Support Manager already added");
        Blockchain_Support_Manager[account] = true;
        emit Added_Blockchain_Support_Manager(account);
    }
    function F44_Remove_Blockchain_Support_Manager(address account) external onlyBlockchainManager {
        require(Blockchain_Support_Manager[account],"The account is not in a Blockchain Support Manager account");
        Blockchain_Support_Manager[account] = false;
        emit Removed_Blockchain_Support_Manager(account);
    }
    function F45_Check_if_Blockchain_Support_Manager(address account) external view returns (bool) {   
        return Blockchain_Support_Manager[account];
    }


    // Bridges and Exchanges 

    function F46_Add_Bridge_Or_Exchange(address account, uint256 proj_fee, uint256 reflections_fee) external onlyOwner {
        BridgeOrExchange[account] = true;
        BridgeOrExchange_TotalProjectFee[account] = proj_fee;
        BridgeOrExchange_ReflectionsFee[account] = reflections_fee;
    }
    function F47_Remove_Bridge_Or_Exchange(address account) external onlyOwner {
        delete BridgeOrExchange[account];
        delete BridgeOrExchange_TotalProjectFee[account];
        delete BridgeOrExchange_ReflectionsFee[account];
    }
    function F48_Check_if_Bridge_Or_Exchange(address account) external view returns (bool) {
        return BridgeOrExchange[account];
    }
    function F49_Get_Bridge_Or_Exchange_Total_Project_Fee(address account) external view returns (uint256) {
        return BridgeOrExchange_TotalProjectFee[account];
    }
    function F50_Get_Bridge_Or_Exchange_Reflections_Fee(address account) external view returns (uint256) {
        return BridgeOrExchange_ReflectionsFee[account];
    }
}