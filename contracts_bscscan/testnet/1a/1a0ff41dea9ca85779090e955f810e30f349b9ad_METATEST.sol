/**
 *Submitted for verification at BscScan.com on 2022-01-25
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
        require(c >= a, "Aaddition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Subtraction overflow");
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
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "Modulo by zero");
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
        require(address(this).balance >= amount, "Insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Call to non-contract");

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
 
    mapping(address => bool) internal Security_Provider; 
    uint256 public Amount_Security_Provider_Accounts;
    
    address public Security_Manager;

    event Owner_Changed(address indexed previousOwner, address indexed newOwner);
    event Changed_Security_Manager(address indexed previous_Security_Manager, address indexed new_Security_Manager);
    event Added_Security_Provider_Account(address indexed account);
    event Removed_Security_Provider_Account(address indexed account);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit Owner_Changed(address(0), msgSender);

        Security_Manager = _msgSender(); 
    }

        //****************************   IMPORTANT   ****************************//
        //
        //  SECURITY REQUIREMENTS - Steps to do upon contract deployment:
        // 
        //  1) Owner should not be Security Manager. 
        //     Therefore upon contract deploy Owner 
        //     should change to a new Security Manager.
        //  
        //  2) The new Security Manager should add a Security Provider account.
        //     Maximum 2 Security Provider accounts are allowed / can be added.
        //
        //  3) Owner should change the Marketing and Blockchain Managers accounts
        //     from the Owner account to other accounts.    
        //
        //************************  ABOUT SECURITY MODEL  ***********************//  
        // 
        //    This contract doesn't use the typical security model 
        //    where an Owner has full control of the token contract.

        //    Each role has its own control permissions which are also limited:
        //    - Owner (CEO)
        //    - Marketing Manager  (Max 2 persons are allowed)
        //    - Blockchain Manager (Max 2 persons are allowed)
        //    - Security Provider  (Max 2 persons are allowed)
        //    - Security Manager   (Max 1 person is allowed)
        //
        //    The Security Provider and Security Manager have the highest permsissions.
        //    For some functions there is also a voting mechanism in place. 
        // 
        //***********************************************************************//

    modifier onlyCEO() {
        require(_owner == _msgSender());
        _;
    }
    // The security of this contract is guaranteed by 
    // and its control is done by the Security Provider
    modifier onlySecurityProvider() {
        require(Security_Provider[_msgSender()] || Security_Manager == _msgSender());
        _;
    }
    // Chief Security Officer
    modifier onlySecurityManager() {
        require(Security_Manager == _msgSender());
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
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

    string private _name = "META44";
    string private _symbol = "META44";

    // Sell price impact tiers 
    //   (% multiplied by 100)
    uint256 public price_impact1;
    uint256 public price_impact2;

    // Fees for buy trades (%)
    uint256 public Buy_ProjectFee;
    uint256 public Buy_ReflectionsFee;

    // Fees for sell trades (%)
    uint256 public Sell_ProjectFee_If_Impacts_Not_Used; 
    uint256 public Sell_ReflectionsFee_If_Impacts_Not_Used;
    
    uint256 public Sell_ProjectFee_Under_Impact1;
    uint256 public Sell_ProjectFee_Above_Impact1;
    uint256 public Sell_ProjectFee_Above_Impact2;
    
    uint256 public Sell_ReflectionsFee_Under_Impact1;
    uint256 public Sell_ReflectionsFee_Above_Impact1;
    uint256 public Sell_ReflectionsFee_Above_Impact2;

    // Fees for normal transfers (%)
    uint256 public Transfer_ProjectFee;
    uint256 public Transfer_ReflectionsFee;

    // Internal. Takes the value of buy
    // sell and transfer fees, respectively
    uint256 private ProjectFee;
    uint256 private ReflectionsFee;

    uint256 private previous_ProjectFee;
    uint256 private previous_ReflectionsFee;   

    // Total Project funding fee split 
    // into portions (%) (total must be 100%) 
    uint256 public ProductDevelopmentFee; 
    uint256 public MarketingFee;          
    uint256 public BlockchainSupportFee;  
    uint256 public ReservaFee;

    // Waiting time between sells (in seconds)
    mapping(address => uint256) private sell_AllowedTime;
    bool private Impact2_Must_Wait_Longer_Before_Next_Sell;

    uint256 public normal_waiting_time_between_sells;
    uint256 public waiting_time_to_sell_after_impact2;                             
    
    address public productDevelopmentWallet;
    address public marketingWallet;
    address public blockchainSupportWallet;
    address public reservaWallet;
    address public communityBeneficialWallet; 

    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private BridgeOrExchange;
    mapping(address => uint256) private BridgeOrExchange_ProjectFee;
    mapping(address => uint256) private BridgeOrExchange_ReflectionsFee;

    // Marketing Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Marketing funds and wallet 
    mapping(address => bool) private Marketing_Manager;  
    uint256 public Marketing_Managers_Counter;

    // Blockchain Manager. 
    // Has no control of the smart contract except do this:  
    // Can only manage the Blockchain Support funds and wallet 
    mapping(address => bool) private Blockchain_Manager;
    uint256 public Blockchain_Managers_Counter;

    // Voting mechanism for updating 
    // the Reserva Fee and Wallet
    mapping(address => bool) public votes;		
    address[] public voting_accounts; 

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
    event Transfer_Fee_Tokens_Sent_To_Community_Beneficial_Wallet(
		address indexed recipient,
		uint256 amount
	);
    event Impact2_Caused_Account_Must_Wait_Longer_Before_Next_Sell(
        address indexed account, 
        uint256 next_time_can_sell
    );

    event Added_Marketing_Manager(address indexed account);
    event Removed_Marketing_Manager(address indexed account);

    event Added_Blockchain_Manager(address indexed account);
    event Removed_Blockchain_Manager(address indexed account);

    modifier lockTheSwap {
        Project_Funding_Swap_Mode = true;
        _;
        Project_Funding_Swap_Mode = false;
    }
    modifier onlyMarketingManager() {
        require(Marketing_Manager[msg.sender]);
        _;
    }
    modifier onlyBlockchainManager() {
        require(Blockchain_Manager[msg.sender]);
        _;
    }
    modifier if_All_Yes_Votes() {
		(address[] memory yes_votes_list, uint256 yes_votes) = F52_Show_Yes_Votes();
        uint256 required_votes_count = Marketing_Managers_Counter + Blockchain_Managers_Counter + 1;
		require( yes_votes == required_votes_count);
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
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;

        productDevelopmentWallet = msg.sender;
        marketingWallet = msg.sender;
        blockchainSupportWallet = msg.sender;
        reservaWallet = msg.sender;
        communityBeneficialWallet = msg.sender;

        Marketing_Managers_Counter;
        Blockchain_Managers_Counter;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

       modifier ExceptAccounts(address account) {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap is not allowed"); 
        require(account != address(this)); 
        require(account != address(0));    
     	require(account != owner());
        require(account != Security_Manager);
        require(!Security_Provider[account]);
        require(!Marketing_Manager[account]);
        require(!Blockchain_Manager[account]);
        require(account != productDevelopmentWallet);
        require(account != marketingWallet);	
        require(account != blockchainSupportWallet);
        require(account != reservaWallet);	
        require(account != communityBeneficialWallet);
        _;
    }
 
    function clear_voting_results() internal {

        uint256 votes_count = voting_accounts.length;
        uint256 i;
        for (i= 0; i < votes_count; i++) {
                 address account = voting_accounts[i];
                 votes[account] = false;    
        }
        delete voting_accounts;
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
    // Disabled, as it is not useful / is not needed and  
    // to minimize the confusion with the total Project Fee
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
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[from], "Sender address is blacklisted");
		require(!isBlacklisted[to], "Recipient address is blacklisted");
        require(from != Security_Manager || to != Security_Manager, "Security Manager is not allowed to trade");
        require(!Security_Provider[from] || !Security_Provider[to] , "Security Provider is not allowed to trade");
        require(Public_Trading_Enabled || 
                isExcludedFromFees[from] || isExcludedFromFees[to], "Public Trading has not been enabled yet.");
        
        if (from != owner() && to != owner() && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                ProjectFee = Buy_ProjectFee; 
                ReflectionsFee  = Buy_ReflectionsFee;
                is_Buy_Trade = true;

            } else if (to == uniswapV2Pair && from != uniswapV2Pair ) {
                     if (normal_waiting_time_between_sells > 0 || waiting_time_to_sell_after_impact2 > 0) {
                        require(block.timestamp > sell_AllowedTime[from]);
                      }

                     if (price_impact1 != 0){
                    
                         if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact1)) {
                             ProjectFee = Sell_ProjectFee_Under_Impact1;
                             ReflectionsFee  = Sell_ReflectionsFee_Under_Impact1;

                          } else if (price_impact2 == 0){
                             ProjectFee = Sell_ProjectFee_Above_Impact1;
                             ReflectionsFee  = Sell_ReflectionsFee_Above_Impact1;

                          } else if (amount < balanceOf(uniswapV2Pair).div(10000).mul(price_impact2 )) {
                             ProjectFee = Sell_ProjectFee_Above_Impact1;
                             ReflectionsFee  = Sell_ReflectionsFee_Above_Impact1;

                          } else {
                             ProjectFee = Sell_ProjectFee_Above_Impact2;
                             ReflectionsFee  = Sell_ReflectionsFee_Above_Impact2;

                             // If the longer waiting time setting is set to non zero   
                             // then the contract will use the longer waiting feature   
                             if (waiting_time_to_sell_after_impact2 > 0) {
                                Impact2_Must_Wait_Longer_Before_Next_Sell = true;
                             }
                         }

                     } else {
                         // If price impact1 is zero then the price impacts   
                         // feature is disabled. And default fees are used.   
                            ProjectFee = Sell_ProjectFee_If_Impacts_Not_Used;
                            ReflectionsFee  = Sell_ReflectionsFee_If_Impacts_Not_Used;
                }
                is_Sell_Trade = true;

            } else if (from != uniswapV2Pair && to != uniswapV2Pair) {

                if (BridgeOrExchange[from]) {
                        ProjectFee = BridgeOrExchange_ProjectFee[from];
                        ReflectionsFee  = BridgeOrExchange_ReflectionsFee[from];
                }
                else if (BridgeOrExchange[to]) {
                        ProjectFee = BridgeOrExchange_ProjectFee[to];
                        ReflectionsFee  = BridgeOrExchange_ReflectionsFee[to];
                }
                else {
                        ProjectFee = Transfer_ProjectFee; 
                        ReflectionsFee  = Transfer_ReflectionsFee;

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
        
        // Check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // Swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        // Calculate BNB for each Project funding wallet
        uint256 productDevelopmentBNB = BalanceBNB.div(100).mul(ProductDevelopmentFee);
        uint256 marketingBNB = BalanceBNB.div(100).mul(MarketingFee);
        uint256 blockchainSupportBNB = BalanceBNB.div(100).mul(BlockchainSupportFee);
        uint256 reservaBNB = BalanceBNB.div(100).mul(ReservaFee);     

       // Send BNB to Project funding wallets 
        payable(productDevelopmentWallet).transfer(productDevelopmentBNB);
        payable(marketingWallet).transfer(marketingBNB);
        payable(blockchainSupportWallet).transfer(blockchainSupportBNB); 
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
            _rOwned[address(communityBeneficialWallet)] = _rOwned[address(communityBeneficialWallet)].add(rLiquidity);
            emit Transfer_Fee_Tokens_Sent_To_Community_Beneficial_Wallet(communityBeneficialWallet, rLiquidity);

            if(isExcludedReflections[address(communityBeneficialWallet)])
            _tOwned[address(communityBeneficialWallet)] = _tOwned[address(communityBeneficialWallet)].add(tLiquidity); 
            emit Transfer_Fee_Tokens_Sent_To_Community_Beneficial_Wallet(communityBeneficialWallet, tLiquidity);
        }
    }
    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(ReflectionsFee).div(100);
    }    
    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(ProjectFee).div(100);
    }    
    function removeAllFees() private {
        if(ReflectionsFee == 0 && ProjectFee == 0) return;
        
        previous_ReflectionsFee = ReflectionsFee;
        previous_ProjectFee = ProjectFee;
        
        ReflectionsFee = 0;
        ProjectFee = 0;
    }    
    function restoreAllFees() private {
        ReflectionsFee = previous_ReflectionsFee;
        ProjectFee = previous_ProjectFee;
    }

    //To enable receiving BNB from PancakeSwap V2 Router when swapping
    receive() external payable {}   


    //*******************  Security  *******************//

	function F01_Security_Check_Account(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return isBlacklisted[account];
    }
    function F02_Blacklist_Malicious_Account(address account) external ExceptAccounts(account) onlySecurityProvider {
        require(!isBlacklisted[account], "Address is already blacklisted");	
        isBlacklisted[account] = true;
    }
    function F03_Whitelist_Account(address account) external onlySecurityProvider {
        require(isBlacklisted[account], "Address is already whitelisted");
        isBlacklisted[account] = false;
    }
    function F04_Add_Security_Provider_Account(address account) external onlySecurityProvider {
        // Maximum two accounts are allowed.
        // When adding the first account or if e.g. both accounts have earlier 
        // been removed then the one must use the Security Manager to add an account.
        require(!Security_Provider[account],"Security Provider already added");
        require(account != owner());
        require(account != Security_Manager);
        require(!Marketing_Manager[account]);
        require(!Blockchain_Manager[account]);
        require(Amount_Security_Provider_Accounts < 2, "Max two accounts are allowed and have been already added");
        
        Security_Provider[account] = true;
        Amount_Security_Provider_Accounts++;
        emit Added_Security_Provider_Account(account);
    }
    function F05_Remove_Security_Provider_Account(address account) external onlySecurityProvider {
        require(Security_Provider[account],"The account is not registered in the contract");
        Security_Provider[account] = false;
        Amount_Security_Provider_Accounts--;
        emit Removed_Security_Provider_Account(account);
    }
    function F06_Check_if_is_Security_Provider_Account(address account) external view returns (string memory, string memory, string memory, uint256) {   
        string memory Message1;
        string memory Message2;
        string memory Message3;

        if (Security_Provider[account]) {
            Message1 =" The account is a Security Provider account";
        } else {
            Message1 =" The account is not a Security Provider account";
        }
        Message2 = " Max 2 Security Providers accounts are allowed.";
        Message3 = " Current amount registered in the contract:";

        return (Message1, Message2, Message3, Amount_Security_Provider_Accounts);
    }
    function F07_Change_Security_Manager(address New_Security_Manager)  public virtual onlySecurityManager {
        require(New_Security_Manager != address(0));
        require(New_Security_Manager != address(this)); 
        address Previous_Security_Manager = Security_Manager;
        Security_Manager = New_Security_Manager;
        emit Changed_Security_Manager(Previous_Security_Manager, New_Security_Manager);
    }
    function F08_Change_Owner(address New_Owner) public virtual onlySecurityProvider {
        require(New_Owner != address(0));
        require(New_Owner != address(this)); 
        address Previous_Owner = _owner;
        _owner = New_Owner;
        isExcludedFromFees[New_Owner] = true;
        isExcludedFromFees[Previous_Owner] = false;
        emit Owner_Changed(Previous_Owner, New_Owner);
    }

    //************  Enable or Disable Trading  ***************//
    
    function F09_Enable_Public_Trading() external onlySecurityProvider {
        Public_Trading_Enabled = true;
    }
    function F10_Disable_Public_Trading() external onlySecurityProvider {
        Public_Trading_Enabled = false;
    }

    //*************  Waiting times for sells  ***************//

    function F11_Check_When_Account_Can_Sell_Again(address account) external view returns (string memory, uint256) {
        // If the parameter "normal_waiting_time_between_sells" or 
        // "waiting_time_to_sell_after_impact2" is non zero 
        // then the waiting time between sells feature is enabled. 
        // If so then this function can be used then to check when
        // is the earliest time that an account can sell again.
        require (balanceOf(account) > 0, "Account has no tokens");  

        string memory Message;

        if ( block.timestamp >= sell_AllowedTime[account]) {
                Message = " Good news !"
                          " The account can do next sell trade at any time."; 
        } else {
                Message = " Be patient please." 
                          " The account cannot sell until the time shown below."
                          " The time is in Unix format. Use free online time conversion"
                          " websites/services to convert to common Date and Time format";
        }
        return (Message, sell_AllowedTime[account]);
    }
    function F12_Shorten_Account_Waiting_Time_Before_Next_Sell(address account, uint256 unix_time) external onlySecurityProvider {
        // Tips:  To allow selling immediately set --> unix_time = 0
        //
        //        When setting it to non zero then use free online 
        //        time conversion website/services to convert
        //        to Unix time the new allowed sell date and time.
        require (block.timestamp < sell_AllowedTime[account], 
                "The account can already sell at any time"); 
        require (unix_time < sell_AllowedTime[account], 
                 "The time must be earlier than currently allowed sell time");
        sell_AllowedTime[account] = unix_time;
    }
    function F13_Set_Normal_Waiting_Time_Between_Sells(uint256 wait_seconds) external onlySecurityProvider {
        // Examples: 
        // To have a 60 seconds wait --> wait_seconds = 60
        //
        // To disable this feature i.e. to have no waiting
        // time then set this to zero --> wait_seconds = 0
        require (wait_seconds <= waiting_time_to_sell_after_impact2 || waiting_time_to_sell_after_impact2 == 0,
                "The normal waiting time cannot be larger than waiting time after price impact2");
        normal_waiting_time_between_sells = wait_seconds;
    }
    function F14_Set_Waiting_Time_for_Next_Sell_after_Impact2(uint256 wait_seconds) external onlySecurityProvider {
        // Requires price_impact2 to be non zero. 
        // And a longer waiting time than the normal wating time  
        require (price_impact2 > 0,
                 "The waiting time after impact2 cannot be set when price_impact2 is 0");
        require (wait_seconds >= normal_waiting_time_between_sells,
                 "The waiting time after impact2 cannot be less than normal waiting time");
        //
        //Examples:   Must wait 3 days --> wait_seconds = 259200
        //                      7 days --> wait_seconds = 604800
        //
        // To disable this longer waiting time after a
        // sell with price impact2 then set this to zero --> wait_seconds = 0
        // 
        // If so then the normal waiting if it is non zero  
        // it will be used for all sells with price impact2. 
        waiting_time_to_sell_after_impact2 = wait_seconds;
    }

    //*************  Price impacts feature  ****************//

    function F15_Set_Sell_Price_Impact1__Multiplied_by_100(uint256 Price_impact1) external onlySecurityProvider {
        require (Price_impact1 < price_impact2 || price_impact2 == 0, 
                 "Price impact1 cannot be larger than price impact2");
        // To support a percentage number with a decimal
        // the percentage is / must be multiplied by 100.
        //
        // Examples:  1% price impact --> Price_impact1 = 100
        //          0.5% price impact --> Price_impact1 =  50
        //
        price_impact1 = Price_impact1; 
        // 
        // If set to 0 then the price impact(s) feature will
        // be disabled entirely i.e. for both impact tiers 
        if (Price_impact1 == 0 && price_impact2 != 0){
            price_impact2 = 0;
            waiting_time_to_sell_after_impact2 = 0;
        }
    }
    function F16_Set_Sell_Price_Impact2__Multiplied_by_100(uint256 Price_impact2) external onlySecurityProvider {
        // Price impact2 can be used only if 
        // price impact1 is non zero / is used.
        require (price_impact1 != 0 && Price_impact2 > price_impact1 || Price_impact2 == 0, 
                 "Price impact2 cannot be less than price impact1"); 
        //
        // Examples:  20% price impact --> Price_impact2 = 2000
        //            30% price impact --> Price_impact2 = 3000
        //
        // To disable the price impact2 tier --> Price_impact2 = 0
        price_impact2 = Price_impact2;       
        if (Price_impact2 == 0 && waiting_time_to_sell_after_impact2 != 0){
            waiting_time_to_sell_after_impact2 = 0;
        }
    }

    //***************  Total Project Fees  *****************//

    function F17_Set_Project_Fee_for_Transfers(uint256 fee_percent) external onlySecurityProvider {
        // Set Project fee for a (normal) transfer between two wallets.
        Transfer_ProjectFee = fee_percent;
    }
    function F18_Set_Project_Fee_for_Buys(uint256 fee_percent) external onlySecurityProvider {
        Buy_ProjectFee = fee_percent;
    }
    function F19_Set_Project_Fee_for_Sells_Under_Impact1(uint256 fee_percent) external onlySecurityProvider {
        require (fee_percent <= Sell_ProjectFee_Above_Impact1 || Sell_ProjectFee_Above_Impact1 == 0,
                "The fee under price impact1 cannot be larger than the fee above price impact1");
        Sell_ProjectFee_Under_Impact1 = fee_percent;
        if (Sell_ProjectFee_Above_Impact1 == 0) {
        Sell_ProjectFee_Above_Impact1 = fee_percent;
        }
        if (Sell_ProjectFee_Above_Impact2 == 0) {
        Sell_ProjectFee_Above_Impact2 = fee_percent;
        }
    }
    function F20_Set_Project_Fee_for_Sells_Above_Impact1(uint256 fee_percent) external onlySecurityProvider {
        require (fee_percent >= Sell_ProjectFee_Under_Impact1,
                "The fee above price impact1 cannot be less than the fee under price impact1");
        require (fee_percent <= Sell_ProjectFee_Above_Impact2 || Sell_ProjectFee_Above_Impact2 == 0,
                "The fee above price impact1 cannot more than the fee above price impact2");
        Sell_ProjectFee_Above_Impact1 = fee_percent;
        if (Sell_ProjectFee_Above_Impact2 == 0) {
            Sell_ProjectFee_Above_Impact2 = fee_percent;  
        }
    }
    function F21_Set_Project_Fee_for_Sells_Above_Impact2(uint256 fee_percent) external onlySecurityProvider { 
        require (fee_percent >= Sell_ProjectFee_Above_Impact1,
                "The fee above price impact2 can not be less than the fee above price impact1");  
        Sell_ProjectFee_Above_Impact2 = fee_percent;
    }
    function F22_Set_Project_Fee_for_Sells_if_Impacts_Not_Used(uint256 fee_percent) external onlySecurityProvider {
        // The Total Project fee for sells  
        // if the price impacts feature is disabled 
        // (i.e. if price impact1 and price impact2 are zero) 
        Sell_ProjectFee_If_Impacts_Not_Used = fee_percent;
    }
        
    //************  Reflection fees  ***************//
    
    function F23_Set_Reflections_Fee_for_Transfers(uint256 fee_percent) external onlySecurityProvider {
        // Set reflections fee for normal transfers between wallets
        Transfer_ReflectionsFee = fee_percent;
    }
    function F24_Set_Reflections_Fee_for_Buys(uint256 fee_percent) external onlySecurityProvider {
        Buy_ReflectionsFee = fee_percent;
    }    
    function F25_Set_Reflections_Fee_for_Sells_Under_Impact1(uint256 fee_percent) external onlySecurityProvider {
        require (fee_percent <= Sell_ReflectionsFee_Above_Impact1 || Sell_ReflectionsFee_Above_Impact1 == 0,
                "The fee under price impact1 cannot be larger than the fee above price impact1");
        Sell_ReflectionsFee_Under_Impact1 = fee_percent;
        if (Sell_ReflectionsFee_Above_Impact1 == 0) {
        Sell_ReflectionsFee_Above_Impact1 = fee_percent;
        }
        if (Sell_ReflectionsFee_Above_Impact2 == 0) {
        Sell_ReflectionsFee_Above_Impact2 = fee_percent;
        }
    }
    function F26_Set_Reflections_Fee_for_Sells_Above_Impact1(uint256 fee_percent) external onlySecurityProvider { 
        require (fee_percent >= Sell_ReflectionsFee_Under_Impact1,
                "The fee above price impact1 cannot be less than the fee under price impact1");
        require (fee_percent <= Sell_ReflectionsFee_Above_Impact2 || Sell_ReflectionsFee_Above_Impact2 == 0,
                "The fee above price impact1 cannot more than the fee above price impact2");
        Sell_ReflectionsFee_Above_Impact1 = fee_percent;
        if (Sell_ReflectionsFee_Above_Impact2 == 0) {
            Sell_ReflectionsFee_Above_Impact2 = fee_percent;
        }
    }
    function F27_Set_Reflections_Fee_for_Sells_Above_Impact2(uint256 fee_percent) external onlySecurityProvider {
        require (fee_percent >= Sell_ReflectionsFee_Above_Impact1,
                "The fee above price impact2 can not be less than the fee above price impact1");  
        Sell_ReflectionsFee_Above_Impact2 = fee_percent;
    }
    function F28_Set_Reflections_Fee_for_Sells_if_Impacts_Not_Used(uint256 fee_percent) external onlySecurityProvider {
        // This Reflections fee is used if 
        // the price impacts feature is disabled 
        // (i.e. if price impact1 and price impact2 are zero)
        Sell_ReflectionsFee_If_Impacts_Not_Used = fee_percent;
    }

    //************  Total Project fee split in portions  **************// 
  
    function F29_Set_Product_Development_Fee_Portion(uint256 fee_percent) external onlyCEO {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100

        uint256 Total_All_Portions =  fee_percent + MarketingFee + BlockchainSupportFee + ReservaFee;
        require(Total_All_Portions <= 100, 
         "When updating this fee portion the sum of all fees portions must be less or equal 100");
        ProductDevelopmentFee = fee_percent;
    }
    function F30_Set_Marketing_Fee_Portion(uint256 fee_percent) external onlyMarketingManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100

        uint256 Total_All_Portions =  ProductDevelopmentFee + fee_percent + BlockchainSupportFee + ReservaFee;
        require(Total_All_Portions <= 100, 
        "When updating this fee portion the sum of all fees portions must be less or equal 100");
        MarketingFee = fee_percent;
    }
    function F31_Set_BlockchainSupport_Fee_Portion(uint256 fee_percent) external onlyBlockchainManager {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100

        uint256 Total_All_Portions =  ProductDevelopmentFee + MarketingFee + fee_percent + ReservaFee;
        require(Total_All_Portions <= 100,
        "When updating this fee portion the sum of all fees portions must be less or equal 100");   
        BlockchainSupportFee = fee_percent;
    }
    function F32_Set_Reserva_Fee_Portion(uint256 fee_percent) external if_All_Yes_Votes onlySecurityProvider {
        // Example: 25% of total Project Fee --> fee_percent = 25
        // IMPORTANT: 
        // ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + ReservaFee = 100   
        
        uint256 Total_All_Portions =  ProductDevelopmentFee + MarketingFee + BlockchainSupportFee + fee_percent;        
        require(Total_All_Portions <= 100, 
        "When updating this fee portion the sum of all fees portions must be less or equal 100");
        ReservaFee = fee_percent;
        // Clear the voting (so next voting can be done correctly)
        clear_voting_results();
    }

     //****************************************************************//
     //               Must pay fees / exclude from fees                //
     //         Receive reflections / exclude from reflections         //
     //****************************************************************// 

    function F33_Enable_Account_Must_Pay_Fees(address account) external onlySecurityProvider {
        // Enable that the account will be charged all fees
        // i.e. it will pay both Project and Reflections fees
        isExcludedFromFees[account] = false;
    }
    function F34_Exclude_Account_From_Paying_Fees(address account) external onlySecurityProvider {
        // Exempt the account from paying any fees i.e. it
        // will pay 0% fee for both Project and Reflection fees 
        isExcludedFromFees[account] = true;
    }
    function F35_Check_if_Account_is_Excluded_from_Paying_Fees(address account) external view returns(bool) {
        // True  - Account is exempted from paying fees 
        //         i.e. it pays 0% fee for both Project and Reflection fees
        // False - Account is charged all fees 
        //         i.e. it pays both project and reflections fees
        return isExcludedFromFees[account];
    }
    function F36_Check_if_Account_is_Excluded_from_Receiving_Reflections(address account) external view returns (bool) {
        // True  - Account doesn't receive reflections 
        // False - Account receives reflections
        return isExcludedReflections[account];
    }
    function F37_Enable_Account_will_Receive_Reflections(address account) external onlySecurityProvider {
        require(isExcludedReflections[account], "Account is already receiving reflections");
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
    function F38_Exclude_Account_from_Receiving_Reflections(address account) external onlySecurityProvider {
        // Account will not receive reflections
        require(!isExcludedReflections[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        isExcludedReflections[account] = true;
            _excluded.push(account);
    }   

    //****************  Project various wallets  ******************//

    function F39_Set_Product_Development_Wallet(address account) external onlyCEO {
        productDevelopmentWallet = account;
    }
    function F40_Set_Marketing_Wallet(address account) external onlyMarketingManager {
        marketingWallet = account;
    }
    function F41_Set_Blockchain_Support_Wallet(address account) external onlyBlockchainManager {
        blockchainSupportWallet = account;
    }
    function F42_Set_Reserva_Wallet(address account) external if_All_Yes_Votes onlySecurityProvider {
        // Use a Multisig wallet, e.g Gnosis Safe) 
        reservaWallet = account;
        // Clear the voting (so next voting can be done correctly)
        clear_voting_results();

    }
    function F43_Set_Community_Beneficial_Wallet(address account) external onlyCEO {
        // The contract uses this wallet to send to this wallet    
        // tokens from the charged Project fee for normal transfers
        communityBeneficialWallet = account;
    }  

    //************  Marketing Manager account  *************//

    function F44_Add_Marketing_Manager(address account) external onlyMarketingManager {
        require(!Security_Provider[account], "A Security Provider cannot have other roles");
        require(account != Security_Manager, "A Security Manager cannot have other roles");
        require(!Marketing_Manager[account],"Marketing Manager already added");   
        require(Marketing_Managers_Counter < 2, "Max two accounts are allowed and have been already added");
        
        if (Marketing_Managers_Counter == 0) {
            require(Security_Provider[msg.sender] || Security_Manager == msg.sender);
        }
        else {require(Marketing_Manager[msg.sender]);}
        
        Marketing_Manager[account] = true;
        Marketing_Managers_Counter++;
        emit Added_Marketing_Manager(account);
    }
    function F45_Remove_Marketing_Manager(address account) external onlyMarketingManager {
        require(Marketing_Manager[account],"The account is not registered in the contract");
        Marketing_Manager[account] = false;
        Marketing_Managers_Counter--;
        emit Removed_Marketing_Manager(account);
    }
    function F46_Check_if_is_Marketing_Manager(address account) external view returns (bool) {   
        return Marketing_Manager[account];
    }


    //*************  Blockchain Manager account  **************//

    function F47_Add_Blockchain_Manager(address account) external onlyBlockchainManager {
        require(!Security_Provider[account], "A Security Provider cannot have other roles");
        require(account != Security_Manager, "A Security Manager cannot have other roles");
        require(!Blockchain_Manager[account],"Blockchain Manager already added");   
        require(Blockchain_Managers_Counter < 2, "Max two accounts are allowed and have been already added");

        if (Blockchain_Managers_Counter == 0) {
            require(Security_Provider[msg.sender] || Security_Manager == msg.sender);
        }
        else {require(Blockchain_Manager[msg.sender]);}
        
        Blockchain_Manager[account] = true;
        Blockchain_Managers_Counter++;
        emit Added_Blockchain_Manager(account);
    }
    function F48_Remove_Blockchain_Manager(address account) external onlyBlockchainManager {
        require(Blockchain_Manager[account],"The account is not registered in the contract");
        Blockchain_Manager[account] = false;
        Blockchain_Managers_Counter--;
        emit Removed_Blockchain_Manager(account);
    }
    function F49_Check_if_is_Blockchain_Manager(address account) external view returns (bool) {   
        return Blockchain_Manager[account];
    }


   //********************  Voting for updating the Reserva Fee and Wallet  ********************//		  
		  
	function F50_Add_Your_Vote(bool true_false) external {
		 require(_owner == msg.sender ||  Marketing_Manager[msg.sender] || Blockchain_Manager[msg.sender]);

         uint256 votes_count = voting_accounts.length;
         uint256 i;
         bool already_voted;

         if (votes_count < 5){
            for (i= 0; i < votes_count; i++) {
                 if ( voting_accounts[i] == msg.sender) {
                     already_voted = true;
                 }
            }
            if (!already_voted) {
                voting_accounts.push(msg.sender);
                votes[msg.sender] = true_false;
            }
         }
	}	  			
	function F51_Show_Which_Accounts_Have_Voted() external view returns (address[] memory) {
			return voting_accounts;
	}
    function F52_Show_Yes_Votes() public view returns (address[] memory, uint256) {
		
		uint256 votes_count = voting_accounts.length;
		uint256 yes_votes_count;
		uint256 i;
        address[] memory yes_votes_list;

		for (i= 0; i < votes_count; i++) {
		
			address account = voting_accounts[i];
			bool vote = votes[account];
			if ( vote == true ) {
				yes_votes_count++;
                yes_votes_list[i] = voting_accounts[i];
			}
		}
        return (yes_votes_list, yes_votes_count);
    }

    //***************  Bridges and Exchanges  ****************// 

    function F53_Add_Bridge_Or_Exchange(address account, uint256 proj_fee, uint256 reflections_fee) external ExceptAccounts(account) onlySecurityProvider {

        BridgeOrExchange[account] = true;
        BridgeOrExchange_ProjectFee[account] = proj_fee;
        BridgeOrExchange_ReflectionsFee[account] = reflections_fee;
    }
    function F54_Remove_Bridge_Or_Exchange(address account) external onlySecurityProvider {
        delete BridgeOrExchange[account];
        delete BridgeOrExchange_ProjectFee[account];
        delete BridgeOrExchange_ReflectionsFee[account];
    }
    function F55_Check_if_is_Bridge_Or_Exchange(address account) external view returns (bool) {
        return BridgeOrExchange[account];
    }
    function F56_Get_Project_Fee_For_Bridge_Or_Exchange(address account) external view returns (uint256) {
        return BridgeOrExchange_ProjectFee[account];
    }
    function F57_Get_Reflections_Fee_For_Bridge_Or_Exchange(address account) external view returns (uint256) {
        return BridgeOrExchange_ReflectionsFee[account];
    }

    //****************  Miscellaneous  ****************//

    function F58_Set_Min_Amount_Tokens_for_ProjectFundingSwap(uint256 amount) external onlySecurityProvider {
        // Example: 10 tokens --> amount = 100000000 (i.e. 10 * 10**7 decimals) = 0.0002%
        minAmountTokens_ProjectFundingSwap = amount;
    }
    function F59_Rescue_Other_Tokens_Sent_To_This_Contract(IERC20 token, address receiver, uint256 amount) external onlySecurityProvider {
        // This feature is very appreciated:
        // To be able to send back to a user other BEP20 tokens 
        // that the user have sent to this contract by mistake.
        require(token != IERC20(address(this)), "Only other tokens can be rescued");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        require(receiver != address(this));
        require(receiver != address(0));
        token.transfer(receiver, amount);
    }    
}