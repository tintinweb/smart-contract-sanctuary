/**
 *Submitted for verification at BscScan.com on 2022-01-21
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
     
    address internal SM = _msgSender();   

    event Changed_Security_Manager(address indexed PSM, address indexed NSM);

    address internal PSM;
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function Security_Manager() public view virtual returns (address) {
        return SM;
    }

    modifier OO() {
        require(_owner == _msgSender() || SM == _msgSender(), "Aborted. You are not Owner");
        _;
    }
    modifier OTH() {
        require(_owner == _msgSender(), "Aborted. You are not main Owner");
        _;
    }
    modifier OSM() {
        require(SM == _msgSender(), "You are not Security Manager");
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

    mapping (address => bool) private IEFF; 
    mapping (address => bool) private IER;
    address[] private _excluded;

    uint8 private _decimals = 7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 5000000 * 10**_decimals; // 500 Million
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "META TEST";
    string private _symbol = "META40";

    uint256 private pi1;
    uint256 private pi2;
    uint256 private BTPF;
    uint256 private BRF;
    uint256 private SDTPF; 
    uint256 private SDRF;
    uint256 private STPFUPI1;
    uint256 private STPFAPI1;
    uint256 private STPFAPI2;
    uint256 private SRFUPI1;
    uint256 private SRFAPI1;
    uint256 private SRFAPI2;
    uint256 private TTPF;
    uint256 private TRF;
    uint256 private TPF;
    uint256 private RF;
    uint256 private PTPF;
    uint256 private PRF;    
    uint256 private PDF; 
    uint256 private MF;          
    uint256 private BSF;  
    uint256 private RSF;
    mapping(address => uint256) private SAT;
    bool private PI2MWLBNS;
    uint256 private NWTBS;
    uint256 private WTTSAPI2;                                
    address private PDW;
    address private MW;
    address private BSW;
    address private RSW;
    address private CBW; 
    mapping(address => bool) private IB;
    mapping(address => bool) private BOE;
    mapping(address => uint256) private BOETPF;
    mapping(address => uint256) private BOERF;
    mapping(address => bool) private MM;    
    mapping(address => bool) private BM; 
    bool private PTE;
    bool private IBT;
    bool private IST;
    bool private PFSM;    
    uint256 private MATPFS =  10 * 10**_decimals; // 0.0002%

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

    event Added_Blockchain_Manager(address indexed account);
    event Removed_Blockchain_Manager(address indexed account);

    event Added_Marketing_Manager(address indexed account);
    event Removed_Marketing_Manager(address indexed account);

    modifier lockTheSwap {
        PFSM = true;
        _;
        PFSM = false;
    }
    modifier OMM() {
       require(MM[msg.sender], "You are not a Marketing Manager");
        _;
    }
    modifier OBM() {
       require(BM[msg.sender], "You are not a Blockchain Manager");
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
        IEFF[owner()] = true;
        IEFF[SM] = true;
        IEFF[address(this)] = true;

        PDW = msg.sender;
        MW = msg.sender;
        BSW = msg.sender;
        RSW = msg.sender;
        CBW = msg.sender;
        
        MM[msg.sender] = true;
        BM[msg.sender] = true;
        
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
        if (IER[account]) return _tOwned[account];
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
    // to minimize the confusion with the Total Project Fee
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
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        require(!IB[from]);
		require(!IB[to]);
        require(PTE || IEFF[from] || IEFF[to]);
        
        if (from != owner() && to != owner() && !IEFF[from] && !IEFF[to]) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                TPF = BTPF; 
                RF  = BRF;
                IBT = true;

            } else if (to == uniswapV2Pair && from != uniswapV2Pair ) {
                     if (NWTBS > 0 || WTTSAPI2 > 0) {
                        require(block.timestamp > SAT[from]);
                      }

                     if (pi1 != 0){
                    
                         if (amount < balanceOf(uniswapV2Pair).div(10000).mul(pi1)) {
                             TPF = STPFUPI1;
                             RF  = SRFUPI1;

                          } else if (pi2 == 0){
                             TPF = STPFAPI1;
                             RF  = SRFAPI1;

                          } else if (amount < balanceOf(uniswapV2Pair).div(10000).mul(pi2 )) {
                             TPF = STPFAPI1;
                             RF  = SRFAPI1;

                          } else {
                             TPF = STPFAPI2;
                             RF  = SRFAPI2;
 
                             if (WTTSAPI2 > 0) {
                                PI2MWLBNS = true;
                             }
                         }

                     } else {
                            TPF = SDTPF;
                            RF  = SDRF;
                }
                IST = true;

            } else if (from != uniswapV2Pair && to != uniswapV2Pair) {

                if (BOE[from]) {
                        TPF = BOETPF[from];
                        RF  = BOERF[from];
                }
                else if (BOE[to]) {
                        TPF = BOETPF[to];
                        RF  = BOERF[to];
                }
                else {
                        TPF = TTPF; 
                        RF  = TRF;

                        if (NWTBS > 0 || WTTSAPI2 > 0)  {
                           SAT[to] = SAT[from];
                        }
                }
                IST = false;
                IBT = false;
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= MATPFS;
        if (
            overMinTokenBalance &&
            !PFSM && 
            from != uniswapV2Pair 
        ) {
            PFS(contractTokenBalance);
        }        

        bool takeAllFees = true;
        
        if(IEFF[from] || IEFF[to]) {
            takeAllFees = false;
        }        
        _tokenTransfer(from,to,amount,takeAllFees);
        restoreAllFees;

        if (IST && PI2MWLBNS) {            
                SAT[from] = block.timestamp + WTTSAPI2;
                emit Impact2_Caused_Account_Must_Wait_Longer_Before_Next_Sell(from, SAT[from]);
                PI2MWLBNS = false;
        }
        else if (IST && NWTBS > 0 ) {
                SAT[from] = block.timestamp + NWTBS;
        }
    }

    function PFS(uint256 contractTokenBalance) private lockTheSwap {
        
        uint256 tokensbeforeSwap = contractTokenBalance;

        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        uint256 PDBNB = BalanceBNB.div(100).mul(PDF);
        uint256 MBNB = BalanceBNB.div(100).mul(MF);
        uint256 BSBNB = BalanceBNB.div(100).mul(BSF);
        uint256 RSBNB = BalanceBNB.div(100).mul(RSF);     

        payable(PDW).transfer(PDBNB);
        payable(MW).transfer(MBNB);
        payable(BSW).transfer(BSBNB); 
        payable(RSW).transfer(RSBNB); 

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
        
        if (IER[sender] && !IER[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!IER[sender] && IER[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!IER[sender] && !IER[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (IER[sender] && IER[recipient]) {
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
        if (IBT || IST) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(IER[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        } else {
            _rOwned[address(CBW)] = _rOwned[address(CBW)].add(rLiquidity);
            emit Transfer_Fee_Tokens_Sent_To_Community_Beneficial_Wallet(CBW, rLiquidity);

            if(IER[address(CBW)])
            _tOwned[address(CBW)] = _tOwned[address(CBW)].add(tLiquidity); 
            emit Transfer_Fee_Tokens_Sent_To_Community_Beneficial_Wallet(CBW, tLiquidity);
        }
    }
    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(RF).div(100);
    }    
    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(TPF).div(100);
    }    
    function removeAllFees() private {
        if(RF == 0 && TPF == 0) return;
        
        PRF = RF;
        PTPF = TPF;
        
        RF = 0;
        TPF = 0;
    }    
    function restoreAllFees() private {
        RF = PRF;
        TPF = PTPF;
    }

    //To enable receiving BNB from PancakeSwap V2 Router when swapping
    receive() external payable {}   



    function Public_Trading_Enabled() public view returns (bool) {
        return PTE;
    }
    function Sell_Normal_Waiting_Time_Between_Sells() public view returns (uint256) {
        return NWTBS;
    }
    function Sell_Waiting_Time_After_Impact2() public view returns (uint256) {
        return WTTSAPI2;
    }
    function Sell_Price_Impact1__Multiplied_by_100() public view returns (uint256) {
        return pi1;
    }
    function Sell_Price_Impact2__Multiplied_by_100() public view returns (uint256) {
        return pi2;
    }
    function Transfer_Total_Project_Fee() public view returns (uint256) {
        return TTPF;
    }
    function Buy_Total_Project_Fee() public view returns (uint256) {
        return BTPF;
    }
    function Sell_Total_Project_Fee_Under_Impact1() public view returns (uint256) {
        return STPFUPI1;
    }
    function Sell_Total_Project_Fee_Above_Impact1() public view returns (uint256) {
        return STPFAPI1;
    }
    function Sell_Total_Project_Fee_Above_Impact2() public view returns (uint256) {
        return STPFAPI2;
    }
    function Sell_Default_Total_Project_Fee() public view returns (uint256) {
        return SDTPF;
    }
    function Transfer_Reflections_Fee() public view returns (uint256) {
        return TRF;
    }
   function Buy_Reflections_Fee() public view returns (uint256) {
        return BRF;
    }
    function Sell_Reflections_Fee_Under_Impact1() public view returns (uint256) {
        return SRFUPI1;
    }
    function Sell_Reflections_Fee_Above_Impact1() public view returns (uint256) {
        return SRFAPI1;
    }
    function Sell_Reflections_Fee_Above_Impact2() public view returns (uint256) {
        return SRFAPI2;
    }
    function Sell_Default_Reflections_Fee() public view returns (uint256) {
        return SDRF;
    }
    function Product_Development_Fee_Portion() public view returns (uint256) {
        return PDF;
    }
    function Marketing_Fee_Portion() public view returns (uint256) {
        return MF;
    }
    function BlockchainSupport_Fee_Portion() public view returns (uint256) {
        return BSF;
    }
    function Reserva_Fee_Portion() public view returns (uint256) {
        return RSF;
    }
    function Product_Development_Wallet() public view returns (address) {
        return PDW;
    }
    function Marketing_Wallet() public view returns (address) {
        return MW;
    }
    function Blockchain_Support_Wallet() public view returns (address) {
        return BSW;
    }
    function Reserva_Wallet() public view returns (address) {
        return RSW;
    }    
    function Community_Beneficial_Wallet() public view returns (address) {
        return CBW;
    }
    function Min_Amount_Tokens_for_ProjectFundingSwap() public view returns (uint256) {
        return MATPFS;
    }

  
	function F01_Security_Check_Account(address account) external view returns (bool) {
        // True - account is blacklisted
        // False -  account is not blacklisted   
        return IB[account];
    }
    function F02_Blacklist_Malicious_Account(address account) external OO {
        require(!IB[account], "Address is already blacklisted");
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted"); 
        require(account != address(this)); 
        require(account != address(0));
     	require(account != owner());
        require(account != SM);
        require(!MM[account]);
        require(!BM[account]);
        require(account != MW);	
        require(account != BSW);
 			
        IB[account] = true;
    }
    function F03_Whitelist_Account(address account) external OO {
        require(IB[account]);
        IB[account] = false;
    }
    function F04_Enable_Public_Trading() external OO {
        PTE = true;
    }
    function F05_Disable_Public_Trading() external OO {
        PTE = false;
    }
    function F06_Check_When_Account_Can_Sell_Again(address account) external view returns (string memory, uint256) {
        // If the parameter "NWTBS" or 
        // "WTTSAPI2" is non zero 
        // then the waiting time between sells feature is enabled. 
        // If so then this function can be used then to check when
        // is the earliest time that an account can sell again.
        require (balanceOf(account) > 0, "Account has no tokens");  

        string memory Message;

        if ( block.timestamp >= SAT[account]) {
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
        return (Message, SAT[account]);
    }
    function F07_Shorten_Account_Waiting_Time_Before_Next_Sell(address account, uint256 unix_time) external OO {
        // Tips:  To allow selling immediately set --> unix_time = 0
        //
        //        When setting it to non zero then use free online 
        //        time conversion website/services to convert
        //        to Unix time the new allowed sell date and time.
        require (block.timestamp < SAT[account], 
                "Aborted. The account can already sell at any time"); 
        require (unix_time < SAT[account], 
                 "Aborted. The time must be earlier than currently allowed sell time");
        SAT[account] = unix_time;
    }
    function F08_Set_Normal_Waiting_Time_Between_Sells(uint256 wait_seconds) external OO {
        // Examples: 
        // To have a 60 seconds wait --> wait_seconds = 60
        //
        // To disable this feature i.e. to have no waiting
        // time then set this to zero --> wait_seconds = 0
        require (wait_seconds <= WTTSAPI2 || WTTSAPI2 == 0);
        NWTBS = wait_seconds;
    }
    function F09_Set_Waiting_Time_For_Next_Sell_After_Impact2(uint256 wait_seconds) external OO {
        require (pi2 > 0);
        require (wait_seconds >= NWTBS);
        //
        //Examples:   Must wait 3 days --> wait_seconds = 259200
        //                      7 days --> wait_seconds = 604800 
        WTTSAPI2 = wait_seconds;
    }
    function F10_Set_Sell_Price_Impact1__Multiplied_by_100(uint256 Price_impact1) external OO {
        require (Price_impact1 < pi2 || pi2 == 0);
        pi1 = Price_impact1; 
        if (Price_impact1 == 0 && pi2 != 0){
            pi2 = 0;
            WTTSAPI2 = 0;
        }
    }    
    function F11_Set_Sell_Price_Impact2__Multiplied_by_100(uint256 Price_impact2) external OO {
        require (pi1 != 0 && Price_impact2 > pi1 || Price_impact2 == 0); 
        pi2 = Price_impact2;       
        if (Price_impact2 == 0 && WTTSAPI2 != 0){
            WTTSAPI2 = 0;
        }
    }
    function F12_Set_Total_Project_Fee_For_Transfers(uint256 fee_percent) external OO {
        TTPF = fee_percent;
    }    
    function F13_Set_Total_Project_Fee_For_Buys(uint256 fee_percent) external OO {
        BTPF = fee_percent;
    }        
    function F14_Set_Total_Project_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external OO {
        require (fee_percent <= STPFAPI1 || STPFAPI1 == 0);
        STPFUPI1 = fee_percent;
        if (STPFAPI1 == 0) {
        STPFAPI1 = fee_percent;
        }
        if (STPFAPI2 == 0) {
        STPFAPI2 = fee_percent;
        }
    }
    function F15_Set_Total_Project_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external OO {
        require (fee_percent >= STPFUPI1);
        require (fee_percent <= STPFAPI2 || STPFAPI2 == 0);
        STPFAPI1 = fee_percent;
        if (STPFAPI2 == 0) {
            STPFAPI2 = fee_percent;  
        }
    }
    function F16_Set_Total_Project_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external OO { 
        require (fee_percent >= STPFAPI1);  
        STPFAPI2 = fee_percent;
    }
    function F17_Set_Default_Total_Project_Fee_For_Sells(uint256 fee_percent) external OO { 
        SDTPF = fee_percent;
    }        
    function F18_Set_Reflections_Fee_For_Transfers(uint256 fee_percent) external OO {
        TRF = fee_percent;
    }
    function F19_Set_Reflections_Fee_for_Buys(uint256 fee_percent) external OO {
        BRF = fee_percent;
    }    
    function F20_Set_Reflections_Fee_For_Sells_Under_Impact1(uint256 fee_percent) external OO {
        require (fee_percent <= SRFAPI1 || SRFAPI1 == 0);
        SRFUPI1 = fee_percent;
        if (SRFAPI1 == 0) {
        SRFAPI1 = fee_percent;
        }
        if (SRFAPI2 == 0) {
        SRFAPI2 = fee_percent;
        }
    }
    function F21_Set_Reflections_Fee_For_Sells_Above_Impact1(uint256 fee_percent) external OO { 
        require (fee_percent >= SRFUPI1);
        require (fee_percent <= SRFAPI2 || SRFAPI2 == 0);
        SRFAPI1 = fee_percent;
        if (SRFAPI2 == 0) {
            SRFAPI2 = fee_percent;
        }
    }
    function F22_Set_Reflections_Fee_For_Sells_Above_Impact2(uint256 fee_percent) external OO {
        require (fee_percent >= SRFAPI1);  
        SRFAPI2 = fee_percent;
    }

    function F23_Set_Default_Reflections_Fee_For_Sells(uint256 fee_percent) external OO {
        SDRF = fee_percent;
    }
    function F24_Set_Product_Development_Fee_Portion(uint256 fee_percent) external OO {
        uint256 New_Total_Fee =  fee_percent + MF + BSF + RSF;
        require(New_Total_Fee <= 100);
        PDF = fee_percent;
    }
    function F25_Set_Marketing_Fee_Portion(uint256 fee_percent) external OMM {
        uint256 New_Total_Fee =  PDF + fee_percent + BSF + RSF;
        require(New_Total_Fee <= 100);
        MF = fee_percent;
    }
    function F26_Set_BlockchainSupport_Fee_Portion(uint256 fee_percent) external OBM {
        uint256 New_Total_Fee =  PDF + MF + fee_percent + RSF;
        require(New_Total_Fee <= 100);   
        BSF = fee_percent;
    }
    function F27_Set_Reserva_Fee_Portion(uint256 fee_percent) external OO {        
        uint256 New_Total_Fee =  PDF + MF + BSF + fee_percent;        
        require(New_Total_Fee <= 100);
        RSF = fee_percent;
    }
    function F28_Enable_Account_Must_Pay_Fees(address account) external OO {
        IEFF[account] = false;
    }
    function F29_Exclude_Account_from_Paying_Fees(address account) external OO {
        IEFF[account] = true;
    }
    function F30_Check_if_Account_is_Excluded_from_Paying_Fees(address account) external view returns(bool) {
        return IEFF[account];
    }
    function F31_check_if_Account_is_Excluded_from_Receiving_Reflections(address account) external view returns (bool) {
        return IER[account];
    }
    function F32_Enable_Account_will_Receive_Reflections(address account) external OO {
        require(IER[account]);
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                IER[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function F33_Exclude_Account_from_Receiving_Reflections(address account) external OO {
        // Account will not receive reflections
        require(!IER[account]);
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        IER[account] = true;
            _excluded.push(account);
    }   
    function F34_Set_Product_Development_Wallet(address account) external OO {
        PDW = account;
    }
    function F35_Set_Marketing_Wallet(address account) external OMM {
        MW = account;
    }
    function F36_Set_Blockchain_Support_Wallet(address account) external OBM {
        BSW = account;
    }
    function F37_Set_Reserva_Wallet(address account) external OO {
        RSW = account;
    }
    function F38_Set_Community_Beneficial_Wallet(address account) external OO {
        CBW = account;
    }
    function F39_Add_Marketing_Manager(address account) external OMM {
        require(!MM[account]);
        MM[account] = true;
        emit Added_Marketing_Manager(account);
    }
    function F40_Remove_Marketing_Manager(address account) external OMM {
        require(MM[account]);
        MM[account] = false;
        emit Removed_Marketing_Manager(account);
    }
    function F41_Check_is_Marketing_Manager(address account) external view returns (bool) {   
        return MM[account];
    }
    function F42_Add_Blockchain_Manager(address account) external OBM {
        require(!BM[account]);
        BM[account] = true;
        emit Added_Blockchain_Manager(account);
    }
    function F43_Remove_Blockchain_Manager(address account) external OBM {
        require(BM[account]);
        BM[account] = false;
        emit Removed_Blockchain_Manager(account);
    }
    function F44_Check_is_Blockchain_Manager(address account) external view returns (bool) {   
        return BM[account];
    }
    function F45_Add_Bridge_Or_Exchange(address account, uint256 proj_fee, uint256 reflections_fee) external OO {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap is not allowed"); 
        require(account != address(this)); 
        require(account != address(0));    
     	require(account != owner());
        require(account != SM);
        require(!MM[account]);
        require(!BM[account]);
        require(account != MW);	
        require(account != BSW);

        BOE[account] = true;
        BOETPF[account] = proj_fee;
        BOERF[account] = reflections_fee;
    }
    function F46_Remove_Bridge_Or_Exchange(address account) external OO {
        delete BOE[account];
        delete BOETPF[account];
        delete BOERF[account];
    }
    function F47_Check_is_Bridge_Or_Exchange(address account) external view returns (bool) {
        return BOE[account];
    }
    function F48_Get_Bridge_Or_Exchange_Total_Project_Fee(address account) external view returns (uint256) {
        return BOETPF[account];
    }
    function F49_Get_Bridge_Or_Exchange_Reflections_Fee(address account) external view returns (uint256) {
        return BOERF[account];
    }
    function F50_Set_Min_Amount_Tokens_for_ProjectFundingSwap(uint256 amount) external OO {
        // Example: 10 tokens --> minTokenAmount = 100000000 (i.e. 10 * 10**7 decimals) = 0.0002%
        MATPFS = amount;
    }
    function F51_Rescue_Other_Tokens_Sent_To_This_Contract(IERC20 token, address receiver, uint256 amount) external OO {
        // This is a very appreciated feature !
        // I.e. to be able to send back to a user other BEP20 
        // tokens that the user have sent to this contract by mistake.   
        require(token != IERC20(address(this)), "Only other tokens can be rescued");
        require(receiver != address(this), "Recipient can't be this contract");
        require(receiver != address(0), "Recipient can't be the zero address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(receiver, amount);
    }
    function F52_Owner_Change_by_Owner(address newOwner) public virtual OTH {
        require(newOwner != address(0));
        require(newOwner != address(this)); 
        _previousOwner = _owner;
        _owner = newOwner;
        IEFF[newOwner] = true;
        if ( _previousOwner != SM) {
        IEFF[_previousOwner] = false;
        }
        emit Owner_Changed_by_Owner(_previousOwner, newOwner);
    }
    function F53_Owner_Change_by_Security_Manager(address newOwner) public virtual OSM {
        require(newOwner != address(0));
        require(newOwner != address(this)); 
        _previousOwner = _owner;
        _owner = newOwner;
        IEFF[newOwner] = true;
        if ( _previousOwner != SM) {
        IEFF[_previousOwner] = false;
        }
        emit Owner_Changed_by_Security_Manager(_previousOwner, newOwner);
    }
    function F54_Security_Manager_Change_by_Security_Manager(address New_Security_Manager)  public virtual OSM {
        require(New_Security_Manager != address(0));
        require(New_Security_Manager != address(this)); 
        PSM = SM;
        SM = New_Security_Manager;
        IEFF[New_Security_Manager] = true;
        if ( PSM != _owner) {
        IEFF[PSM] = false;
        }
        emit Changed_Security_Manager(PSM, New_Security_Manager);
    }
}