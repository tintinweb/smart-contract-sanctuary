/**
 *Submitted for verification at BscScan.com on 2022-01-13
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
        // Usually one needs also to execute F28_Enable_Must_Pay_Fees function
        // if the old Owner will not be excluded anymore from paying fees
        // And also run F29_Exclude_from_Paying_Fees for the new Owner 
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit Owner_Changed(_previousOwner, newOwner);
    }
    function Z2_Owner_Change_by_Security_Manager(address newOwner) public virtual onlySecurityManager {
        // IMPORTANT: 
        // Usually one needs also to execute F28_Enable_Must_Pay_Fees function
        // if the old Owner will not be excluded anymore from paying fees
        // And also run F29_Exclude_from_Paying_Fees for the new Owner  
        require(newOwner != address(0), "Aborted. The new owner can't be the zero address");
        _previousOwner = _owner;
        _owner = newOwner;
        emit Owner_Changed_by_Security_Manager(_previousOwner, newOwner);

    }
    function Z3_Change_Security_Manager(address newSecurityManager)  public virtual onlySecurityManager {
        // IMPORTANT: 
        // Usually one needs also to execute F28_Enable_Must_Pay_Fees function
        // if the old Security Manager will not be excluded anymore from paying fees
        // And also run F29_Exclude_from_Paying_Fees for the new Security Manager  
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
    string private _symbol = "META31";


    // Fees for buy trades
    uint256 public Buy_TotalProjectFee;
    uint256 public Buy_ReflectionsFee;

    // Fees for sell trades

    uint256 public Sell_Default_Total_ProjectFee; 
    uint256 public Sell_Default_ReflectionsFee;
    
    uint256 public Sell_Total_ProjectFee_Level_A;
    uint256 public Sell_Total_ProjectFee_Level_B;
    uint256 public Sell_Total_ProjectFee_Level_C;
    
    uint256 public Sell_ReflectionsFee_Level_A;
    uint256 public Sell_ReflectionsFee_Level_B;
    uint256 public Sell_ReflectionsFee_Level_C;

    // Sell price impact levels  
    uint256 public price_impact1;
    uint256 public price_impact2;

    // Waiting time between sells
    bool private Impact2_Must_Wait_Longer_Before_Next_Sell;
    mapping(address => uint256) private sell_AllowedTime;

    uint256 public normal_waiting_time_between_sells;
    uint256 public impact2_longer_waiting_time_before_next_sell;                             
      
    // Fees for normal transfers
    uint256 public transfer_TotalProjectFee;
    uint256 public transfer_ReflectionsFee;

    // These take the value from buy, sell
    // and transfer fees values, respectively
    uint256 public  totalProjectFee;
    uint256 public  reflectionsFee;

    uint256 private previous_totalProjectFee;
    uint256 private previous_ReflectionsFee;
   
    // Total Project funding fee is
    // further split into these fees
    uint256 public productDevelopmentFee; 
    uint256 public marketingFee;          
    uint256 public blockchainSupportFee;  
    uint256 public reservaFee;
    
    address public _productDevelopmentWallet;
    address public _marketingWallet;
    address public _blockchainSupportWallet;
    address public _reservaWallet;
    address public _communityWallet;       

    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_TotalProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;

    // Blockchain Support Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Blockchain Support funds and wallet 
    mapping(address => bool) private Blockchain_Support_Manager; 

    // Marketing Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Marketing funds and wallet 
    mapping(address => bool) private Marketing_Manager;    
    
    bool public Public_Trading_Enabled;
    bool private is_Buy_Trade;
    bool private is_Sell_Trade;

    bool private Project_Funding_Swap_Mode;    
    uint256 public minAmountTokens_ProjectFundingSwap =  10 * 10**_decimals; // 0.0002%

    bool public AllFeesEnabled = true;

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
    event Impact2_So_Account_Must_Wait_Longer_Before_Next_Sell(
        address indexed account, 
        uint256 next_time_can_sell
    );

    event Added_Blockchain_Support_Manager(address indexed account);
    event Removed_Blockchain_Support_Manager(address indexed account);

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
       require(Blockchain_Support_Manager[msg.sender], "You are not a Blockchain Support Manager");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // PancakeSwap V2 Router
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        
        // For testing in BSC Testnet
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

        _productDevelopmentWallet = msg.sender;
        _marketingWallet = msg.sender;
        _blockchainSupportWallet = msg.sender;
        _reservaWallet = msg.sender;
        _communityWallet = msg.sender;
        
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
        require(Public_Trading_Enabled || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Public Trading has not been enabled yet.");
        
        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                is_Buy_Trade = true;
                totalProjectFee = Buy_TotalProjectFee; 
                reflectionsFee  = Buy_ReflectionsFee;
            }
            
            if (to == uniswapV2Pair && from != uniswapV2Pair ) {

                if (normal_waiting_time_between_sells > 0) {
                    require(block.timestamp > sell_AllowedTime[from]);
                }                
                
                is_Sell_Trade = true;

                if (price_impact1 > 0){
                    
                    if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact1)) {
                        // Level A fees when under price impact1
                           totalProjectFee = Sell_Total_ProjectFee_Level_A;
                           reflectionsFee  = Sell_ReflectionsFee_Level_A;

                    } else if (price_impact2 > 0){
                              if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact2 )) {
                                 // Level B fees when between price impact1 and impact2
                                    totalProjectFee = Sell_Total_ProjectFee_Level_B;
                                    reflectionsFee  = Sell_ReflectionsFee_Level_B;

                                } else {
                                   // Level C fees when above price impact2
                                      totalProjectFee = Sell_Total_ProjectFee_Level_C;
                                      reflectionsFee  = Sell_ReflectionsFee_Level_C;

                                   // Use the longer wating time feature   
                                   // if its value is set to more than zero  
                                   if (impact2_longer_waiting_time_before_next_sell > 0) {
                                       Impact2_Must_Wait_Longer_Before_Next_Sell = true;
                                    }
                                }

                    } else { 
                            // As price impact2 is set to zero then apply
                            // Level_B fees for all sells above price impact1.
                               totalProjectFee = Sell_Total_ProjectFee_Level_B;
                               reflectionsFee  = Sell_ReflectionsFee_Level_B;
                    }
                
                } else {
                         // The price impact1 is set to zero. Then the price impact 
                         // functionality is not used. It is not the intended scenario 
                         // of this contract. But a project may start with a simpler   
                         // setup. And later on may decide to use the price impacts.  
                            totalProjectFee = Sell_Default_Total_ProjectFee;
                            reflectionsFee  = Sell_Default_ReflectionsFee;
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

                        // To prevent evading the sell waiting time by sending tokens 
                        // to another wallet and then selling from it then we set same
                        // sell waiting time for the recipient wallet.
                        if (normal_waiting_time_between_sells > 0)  {
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
            !Project_Funding_Swap_Mode && 
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

        if (is_Sell_Trade && Impact2_Must_Wait_Longer_Before_Next_Sell) {            
                sell_AllowedTime[from] = block.timestamp + impact2_longer_waiting_time_before_next_sell;
                emit Impact2_So_Account_Must_Wait_Longer_Before_Next_Sell(from, sell_AllowedTime[from]);
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
        payable(_productDevelopmentWallet).transfer(productDevelopmentBNB);

        // Send BNB to fund Marketing
        payable(_marketingWallet).transfer(marketingBNB);

        // Send BNB to fund Blockchain products and support
        payable(_blockchainSupportWallet).transfer(blockchainSupportBNB); 

        // Send BNB to the Reserva wallet 
        payable(_reservaWallet).transfer(reservaBNB); 

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
            emit Transfer_Fee_Tokens_Sent_To_Community_Wallet(_communityWallet, rLiquidity);

            if(_isExcludedRewards[address(_communityWallet)])
            _tOwned[address(_communityWallet)] = _tOwned[address(_communityWallet)].add(tLiquidity); 
            emit Transfer_Fee_Tokens_Sent_To_Community_Wallet(_communityWallet, tLiquidity);
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

    //To recieve BNB from PancakeSwap V2 Router when swapping
    receive() external payable {}   


    // Security functions

	function F01_Security_Check(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    function F02_Blacklist_Malicious_Account(address account) external onlyOwner {
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
    function F03_Whitelist_Account(address account) external onlyOwner {
        require(isBlacklisted[account], "Address is already whitelisted");

        isBlacklisted[account] = false;
    }


    // Enable or Disable Trading
    
    function F04_Enable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = true;
    }
    function F05_Disable_Public_Trading() external onlyOwner {
        Public_Trading_Enabled = false;
    }


    // Waiting times for sells

    function F06_Check_When_Account_Can_Sell_Again(address account) external view returns (string memory, uint256) {
        // If the setting "normal_waiting_time_between_sells" is non zero 
        // then the waiting time between sells feature is enabled. 
        // This function can be used then to check when is the earliest
        // time an account can sell again.
        require (balanceOf(account) > 0, "Account has no tokens"); 
        string memory Message = " The time format is Unix time"
                                " Tip: Use free online time conversion websites"
                                " to convert from Unix time to a date and time.";
        return (Message, sell_AllowedTime[account]);     
    }
    function F07_Clear_Account_Longer_Waiting_Time_Before_Next_Sell(address account) external onlyOwner {           
        sell_AllowedTime[account] = block.timestamp;
    }
    function F08_Set_Normal_Waiting_Time_Between_Sells(uint256 normal_wait_seconds) external onlyOwner {
        // Examples: 
        // To have a 60 seconds wait --> normal wait_wait_secs = 60
        //
        // To disable this feature i.e. to have no waiting
        // then set it to zero --> normal wait_wait_secs = 0
        normal_waiting_time_between_sells = normal_wait_seconds;
    }
    function F09_Set_Impact2_Longer_Waiting_Time_Before_Next_Sell(uint256 longer_wait_secs) external onlyOwner {           
        //Examples:   Must wait 3 days --> wait_secs = 259200
        //                      7 days --> wait_secs = 604800
        //
        // To disable this feature i.e. to have the normal waiting time 
        // for impact2 then set this to zero --> longer_wait_secs = 0
        impact2_longer_waiting_time_before_next_sell = longer_wait_secs;
    }


    // Price impacts (feature is disabled if the value is zero)

    function F10_Set_Sell_Price_Impact1__Multiplied_by_100(uint256 Price_impact1) external onlyOwner {
        // To support setting a percentage number that has a
        // comma the actual percentage number is multiplied by 100
        //
        // Examples:  1% price impact --> Price_impact1 = 100
        //          0.5% price impact --> Price_impact1 =  50
        //
        // To disable the impact1 tier set it to zero ---> Price_impact1 = 0  
        price_impact1 = Price_impact1;
    }
    function F11_Set_Sell_Price_Impact2__Multiplied_by_100(uint256 Price_impact2) external onlyOwner {
        require (price_impact1 > 0, "Cannot set price impact2 if/when impact1 is zero");
        //
        // Examples:  20% price impact --> Price_impact2 = 2000
        //            30% price impact --> Price_impact2 = 3000
        //
        // To disable the impact2 tier set it to zero --> Price_impact2 = 0
        price_impact2 = Price_impact2;
    }

    // Total Project Fees

    function F12_Set_Total_Project_Fee_For_Transfers(uint256 fee_percent) external onlyOwner {
        // Set project fee for transfers from wallet to wallet
        transfer_TotalProjectFee = fee_percent;
    }
    function F13_Set_Total_Project_Fee_For_Buys(uint256 fee_percent) external onlyOwner {
        Buy_TotalProjectFee = fee_percent;
    }
    function F14_Set_Total_Project_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external onlyOwner {
        // Set project fee up to price impact
        Sell_Total_ProjectFee_Level_A = fee_percent;
    }
    function F15_Set_Total_Project_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external onlyOwner {
        // If you need only one fee (a flat fee) then set this fee 
        // to same value as for Sell_Total_ProjectFee_Level_A
        // or set in F10 the price impact1 to 100% i.e. Price_Impact1 = 10000    
        Sell_Total_ProjectFee_Level_B = fee_percent;
    }
    function F16_Set_Total_Project_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external onlyOwner {
        // If you need only one fee (a flat fee) then set this fee 
        // to same value as for Sell_Total_ProjectFee_Level_A
        // or set in F10 the price impact1 to 100% i.e. Price_Impact1 = 10000    
        Sell_Total_ProjectFee_Level_C = fee_percent;
    }
    function F17_Set_Default_Total_Project_Fee(uint256 fee_percent) external onlyOwner {
        // The default setting is used only if/when price impacts feature is not used.
        Sell_Default_Total_ProjectFee = fee_percent;
    }
    
    
    // Reflection fees
    
    function F18_Set_Reflections_Fee_For_Transfers(uint256 fee_percent) external onlyOwner {
        // Set reflections fee for transfers from wallet to wallet
        transfer_ReflectionsFee = fee_percent;
    }
    function F19_Set_Reflections_Fee_for_Buys(uint256 fee_percent) external onlyOwner {
        Buy_ReflectionsFee = fee_percent;
    }    
    function F20_Set_Reflections_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external onlyOwner {
        // Set reflection fee for sells up to price impact
        Sell_ReflectionsFee_Level_A = fee_percent;
    }
    function F21_Set_Reflections_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external onlyOwner {
        // Set total project fee for sells above price impact1 
        Sell_ReflectionsFee_Level_B = fee_percent;
    }
    function F22_Set_Reflections_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external onlyOwner {
        // Set total project fee for sells above price impact2 
        Sell_ReflectionsFee_Level_C = fee_percent;
    }
    function F23_Set_Default_Reflections_Fee(uint256 fee_percent) external onlyOwner {
        // The default setting is used only if/when price impacts feature is not used.
        Sell_Default_ReflectionsFee = fee_percent;
    }


    // Total Project fee is split in portions 
  
    function F24_Set_Product_Development_Fee_Portion(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + marketingFee + blockchainSupportFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the total of all fees portions must be less or equal 100");
        productDevelopmentFee = fee_percent;
    }
    function F25_Set_Marketing_Fee_Portion(uint256 fee_percent) external onlyMarketingManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + blockchainSupportFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the total of all fees portions must be less or equal 100");
        marketingFee = fee_percent;
    }
    function F26_Set_BlockchainSupport_Fee_Portion(uint256 fee_percent) external onlyBlockchainManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !

        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + marketingFee + reservaFee;
        require(New_Total_Fee <= 100, "Aborted. When updating the total of all fees portions must be less or equal 100");   
        blockchainSupportFee = fee_percent;
    }
    function F27_Set_Reserva_Fee_Portion(uint256 fee_percent) external onlyOwner {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100 <-- Mandatory rule !   
        
        uint256 New_Total_Fee =  fee_percent + productDevelopmentFee + marketingFee + blockchainSupportFee;        
        require(New_Total_Fee <= 100, "Aborted. When updating the total of all fees portions must be less or equal 100");
        reservaFee = fee_percent;
    }


    // Must pay fees, exclude from fees.
    // Receive reflections, get no reflections. 

    function F28_Enable_Must_Pay_Fees(address account) external onlyOwner {
        // Enable will be charged all fees
        // i.e. will pay both project and reflections fees
        _isExcludedFromFee[account] = false;
    }
    function F29_Exclude_from_Paying_Fees(address account) external onlyOwner {
        // Exempt from paying any fees 
        // i.e. will pay 0% fee for both project and reflection fees 
        _isExcludedFromFee[account] = true;
    }
    function F30_Check_is_Excluded_from_Paying_Fees(address account) external view returns(bool) {
        // True  - Is exempted from paying any fees 
        //         i.e. pays 0% fee for both project and reflection fees
        // False - Is charged all fees 
        //         i.e. pays both project and reflections fees
        return _isExcludedFromFee[account];
    }
    function F31_check_if_Excluded_from_Receiving_Reflections(address account) external view returns (bool) {
        // True  - Account doesn't receive reflections 
        // False - Account receives reflections
        return _isExcludedRewards[account];
    }
    function F32_Enable_Receives_Reflections(address account) external onlyOwner {
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
    function F33_Exclude_from_Receiving_Reflections(address account) external onlyOwner {
        // Will not receive reflections
        require(!_isExcludedRewards[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedRewards[account] = true;
        _excluded.push(account);
    }   


    // Project wallets

    function F34_Set_Product_Development_Wallet(address account) external onlyOwner {
        _productDevelopmentWallet = account;
    }
    function F35_Set_Marketing_Wallet(address account) external onlyMarketingManager {
        _marketingWallet = account;
    }
    function F36_Set_BlockchainSupport_Wallet(address account) external onlyBlockchainManager {
        _blockchainSupportWallet = account;
    }
    function F37_Set_Reserva_Wallet(address account) external onlyOwner {
        _reservaWallet = account;
    }
    function F38_Set_Community_Wallet(address account) external onlyOwner {
        _communityWallet = account;
    }


    // Marketing Manager account

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


    // Blockchain Support Manager account

    function F42_Add_Blockchain_Support_Manager(address account) external onlyBlockchainManager {
        require(!Blockchain_Support_Manager[account],"Blockchain Support Manager already added");
        Blockchain_Support_Manager[account] = true;
        emit Added_Blockchain_Support_Manager(account);
    }
    function F43_Remove_Blockchain_Support_Manager(address account) external onlyBlockchainManager {
        require(Blockchain_Support_Manager[account],"The account is not in a Blockchain Support Manager account");
        Blockchain_Support_Manager[account] = false;
        emit Removed_Blockchain_Support_Manager(account);
    }
    function F44_Check_is_Blockchain_Support_Manager(address account) external view returns (bool) {   
        return Blockchain_Support_Manager[account];
    }


    // Bridges and Exchanges 

    function F45_Add_Bridge_Or_Exchange(address account, uint256 proj_fee, uint256 reflections_fee) external onlyOwner {
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

    // Miscellaneous

    function F50_Set_Min_Amount_Tokens_for_ProjectFundingSwap(uint256 amount) external onlyOwner {
        // Example: 10 tokens --> minTokenAmount = 100000000 (i.e. 10 * 10**7 decimals) = 0.0002%
        minAmountTokens_ProjectFundingSwap = amount;
    }

    function F51_Enable_All_Fees() external onlyOwner {
        // Enable project fee and reflections fee.
        // This function is rarely used (fees are usually always enabled)
        AllFeesEnabled = true;
    }
    function F52_Disable_All_Fees() external onlyOwner {
        // Disable project fee and reflections fee
        // This is function is rarely used (fees are usually always enabled)
        AllFeesEnabled = false;
    }
    function F52_Rescue_Other_Tokens_In_This_Contract(IERC20 token, address receiver, uint256 amount) external onlyOwner {
        require(token != IERC20(address(this)), "Only other tokens can be rescued");
        require(receiver != address(this), "Recipient can't be this contract");
        require(receiver != address(0), "Recipient can't be the zero address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(receiver, amount);
    }
}