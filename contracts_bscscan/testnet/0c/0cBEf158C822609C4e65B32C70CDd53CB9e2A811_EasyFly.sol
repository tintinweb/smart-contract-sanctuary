/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

/**
 
######################################  ENGLISH  ################################################

///////////////////////////////////////////////////////////////////////////////////////////////////
//	Attention, do not buy until launch, this with 99% rate for both buying and selling,			/// 
//		these rates will change on the day and time of launch. see our Telegram					///
///////////////////////////////////////////////////////////////////////////////////////////////////

Launching on 08.09.2021 at 21:00 Brasilia Hours (-3 UTC)

Portuguese Telegram	=	https://t.me/easyflytoken

Telegram English	=	https://t.me/easyflytokeneng

Supply				=	1,000,000,000

- >> Fee for Holders << -
		10% of all transactions are redistributed to all EasyFly holdes That means
			you can earn passive income simply by holding EasyFly in your wallet.
  
- >> System Fee << -
		5% of all transactions are sent to EasyFly's System wallet That means
			we will invest a good amount for the system and also for sweepstakes.

- >> Anti-Pump and Anti-Dump<< -
		At Launch, the maximum buy and sell amount per transaction is 0.1% ( 2,000,000 ) of the token supply.
			After 48 hours of launching, the maximum buy and sell amount per transaction will change is 0.5% 
			(5,000,000 ) of the token supply.


///////////////////////////////////////////////////////////////////////////////////////////////////
//	Atenção, não compre até o lançamento, esta com taxa de 99% tanto para compra e para venda, 	///
//		esta taxas serão mudada no dia e hora do lançamento. veja em nossos Telegram    	  	///
///////////////////////////////////////////////////////////////////////////////////////////////////

######################################  PORTUGUES  ################################################

Lançamento dia 08.09.2021 as 21:00 Horas de Brasilia (-3 UTC)

Telegram Portugues	=	https://t.me/easyflytoken

Telegram English	=	https://t.me/easyflytokeneng

Supply              =   1.000.000.000

- >> Taxa para Holders << - 
		10% de todas as transações são redistribuídas para todos os holdes EasyFly Isso significa que 
			você pode ganhar uma renda passiva simplesmente segurando EasyFly em sua carteira.
  
- >> Taxa para Sistema << - 
		5% de todas as transações são enviadas para carteira de Sistema da EasyFly Isso significa que 
			investiremos um valor bom para o sistema e tambem para sorteios.

- >> Sistema Anti-Despejo<< - 
		Vender acima de 0,25% do Supply, taxa extra de 2.5%
		Vender acima de 0,50% do Supply, taxa extra de 5%
		Vender acima de 1% do Supply, taxa extra de 10%
*/

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract EasyFly is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private tokenHoldersEnumSet;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromLottery;


    address[] private _excluded;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    
    uint256 private _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 lottery;
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
    }
    TotFeesPaidStruct public totFeesPaid;

    string private constant _name = "Easy Fly Token";
    string private constant _symbol = "EasyFly";

    uint256 public _minLottoBalance = 500000 * 10**_decimals; // 500 Mil para participar da loteria

    struct feeRatesStruct {
      uint256 rfi;
      uint256 lottery;
      uint256 marketing;
      uint256 liquidity;
      uint256 burn;
    }

    struct balances {
      uint256 marketing_balance;
      uint256 lp_balance;
    }

    balances public contractBalance; 
    
    
    feeRatesStruct public buyRates = feeRatesStruct(
     {rfi: 80,
      lottery: 0,
      marketing: 70,
      liquidity: 0,
      burn: 0
    });

    feeRatesStruct public sellRates = feeRatesStruct(
     {rfi: 100,
      lottery: 0,
      marketing: 100,
      liquidity: 0,      
      burn: 0
    });

    feeRatesStruct private appliedFees;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rLottery;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 rBurn;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tLottery;
      uint256 tMarketing;
      uint256 tLiquidity;
      uint256 tBurn;
    }

    IUniswapV2Router02 public PancakeSwapV2Router;
    address public pancakeswapV2Pair;
    address payable public marketingAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    struct antiwhale {
      uint256 selling_treshold;
      uint256 extra_tax;
    }

    antiwhale[3] public antiwhale_measures;

    uint256 private numTokensToSwap = _tTotal/1000;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmount, uint256 bnbAmount);

    event LotteryWon(address winner, uint256 amount);


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _rOwned[owner()] = _rTotal;
        
//      IUniswapV2Router02 _PancakeSwapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //BSC mainnet
        IUniswapV2Router02 _PancakeSwapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //BSC Testnet
        pancakeswapV2Pair = IUniswapV2Factory(_PancakeSwapV2Router.factory())
            .createPair(address(this), _PancakeSwapV2Router.WETH());

        PancakeSwapV2Router = _PancakeSwapV2Router;
        marketingAddress = payable(0x9dA806F80f9FDe9bf98E5f1a6419e5aD939B857A);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));

        _isExcluded[pancakeswapV2Pair] = true;
        _excluded.push(pancakeswapV2Pair);
        
        _isExcludedFromLottery[owner()] = true;
        _isExcludedFromLottery[marketingAddress] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[pancakeswapV2Pair] = true;
        _isExcludedFromLottery[0x000000000000000000000000000000000000dEaD] = true;

        antiwhale_measures[0] = antiwhale({selling_treshold: _tTotal*25/10000, extra_tax: 25});
        antiwhale_measures[1] = antiwhale({selling_treshold: _tTotal*50/10000, extra_tax: 50});
        antiwhale_measures[2] = antiwhale({selling_treshold: _tTotal/100, extra_tax: 100});

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: valor da transferencia excede o limite"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: reducao da provisao abaixo de zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "A quantidade deve ser menor que a oferta");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "A quantidade deve ser menor que o total de reflexos");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "A conta ja foi excluida");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function excludeFromLottery(address account) public onlyOwner() {
        require(!_isExcludedFromLottery[account], "A conta ja foi excluida");
        _isExcludedFromLottery[account]=true;
    }

    function excludeFromAll(address account) public onlyOwner() {
        _isExcludedFromLottery[account]=true;
        if(!_isExcluded[account])
        {
        _isExcluded[account] = true;
         if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _excluded.push(account);
        }
        _isExcludedFromFee[account] = true;
        
        tokenHoldersEnumSet.remove(account);
    }

    function includeInLottery(address account) public onlyOwner() {
        require(_isExcludedFromLottery[account], "A conta ja esta incluida");
        _isExcludedFromLottery[account]=false;
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "A conta nao foi excluida");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);

(to_return.rAmount,to_return.rTransferAmount,to_return.rRfi,to_return.rLottery,to_return.rMarketing,to_return.rLiquidity,to_return.rBurn) = _getRValues(to_return, tAmount, takeFee, _getRate());

        return to_return;

    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*appliedFees.rfi/1000;
        s.tLottery = tAmount*appliedFees.lottery/1000;
        s.tMarketing = tAmount*appliedFees.marketing/1000;
        s.tLiquidity = tAmount*appliedFees.liquidity/1000;
        s.tBurn = tAmount*appliedFees.burn/1000;
        s.tTransferAmount = tAmount-s.tRfi -s.tLottery -s.tMarketing -s.tLiquidity -s.tBurn; 
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rLottery, uint256 rMarketing, uint256 rLiquidity, uint256 rBurn) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }

        rRfi= s.tRfi*currentRate;
        rLottery= s.tLottery*currentRate;
        rMarketing= s.tMarketing*currentRate;
        rLiquidity= s.tLiquidity*currentRate;
        rBurn= s.tBurn*currentRate;

        rTransferAmount= rAmount- rRfi-rLottery-rMarketing-rLiquidity-rBurn;

        return ( rAmount,  rTransferAmount,  rRfi,  rLottery,  rMarketing,  rLiquidity,  rBurn);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal = _rTotal-rRfi;
        totFeesPaid.rfi+=tRfi;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        contractBalance.marketing_balance+=tMarketing;
        totFeesPaid.marketing+=tMarketing;
        _rOwned[address(this)] = _rOwned[address(this)]+rMarketing;
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)] = _tOwned[address(this)]+tMarketing;
        }
    }
    
    function _takeLiquidity(uint256 rLiquidity,uint256 tLiquidity) private {
        contractBalance.lp_balance+=tLiquidity;
        totFeesPaid.liquidity+=tLiquidity;
        
        _rOwned[address(this)] = _rOwned[address(this)]+rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tLiquidity;
    }

    function random(uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed%to;
    }

    function lotterize() private view returns(address) {

				uint256 randomNumber;
                address chosenWinner;
				uint256 ownedAmount;
                uint256 trial;
                uint256 numHolders = tokenHoldersEnumSet.length();
                
                if(numHolders>0)
                {
                randomNumber = random( numHolders, balanceOf(address(this)));
                do
                {   randomNumber = random( numHolders, balanceOf(address(this))+trial );
                    chosenWinner = tokenHoldersEnumSet.at(randomNumber);
				    ownedAmount = balanceOf(chosenWinner);
                    if (ownedAmount >= _minLottoBalance && !_isExcludedFromLottery[chosenWinner]) {
						return chosenWinner;
				    }
                    trial+=1;
                }while(trial<2);
                }
                return address(0); //no winner, we'll burn
    }

    function _takeLottery(uint256 rLottery,uint256 tLottery) private returns(address winner) {
        winner = lotterize();
        if(winner == address(0))
        {
            _takeBurn(rLottery,tLottery);
        }
        else
        {
            _rOwned[winner] = _rOwned[winner]+rLottery;
            if(_isExcluded[winner])
                {_tOwned[winner] = _tOwned[winner]+tLottery;
                }
            totFeesPaid.lottery+=tLottery;
        }

        return winner;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn+=tBurn;

        _tTotal = _tTotal-tBurn;
        _rTotal = _rTotal-rBurn;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: aprovar do endereco zero");
        require(spender != address(0), "ERC20: aprovar para o endereco zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transferencia do endereco zero");
        require(to != address(0), "ERC20: transferencia para o endereco zero");
        require(amount > 0, "O valor da transferencia deve ser maior que zero");
        require(amount <= balanceOf(from),"Voce esta tentando transferir mais do que seu saldo");
        
        if (contractBalance.lp_balance>= numTokensToSwap && !inSwapAndLiquify && from != pancakeswapV2Pair && swapAndLiquifyEnabled) {
            swapAndLiquify(numTokensToSwap);
        }

        if (contractBalance.marketing_balance>= numTokensToSwap && !inSwapAndLiquify && from != pancakeswapV2Pair && swapAndLiquifyEnabled) {

            swapAndSendToMarketing(numTokensToSwap);
        }        

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    function getAntiwhaleFee(uint256 amount) internal view returns(uint256 sell_tax) {
    
        if(amount < antiwhale_measures[0].selling_treshold) {
          sell_tax=0;
        }
        else if(amount < antiwhale_measures[1].selling_treshold) {
          sell_tax = antiwhale_measures[0].extra_tax;
        }
        else if(amount < antiwhale_measures[2].selling_treshold) {
          sell_tax = antiwhale_measures[1].extra_tax;
        }
        else { sell_tax = antiwhale_measures[2].extra_tax; }

      return sell_tax;
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        if(takeFee)
        {

        if(sender == pancakeswapV2Pair)
        {
            appliedFees = buyRates;
        }
        else
        {
            appliedFees =sellRates;
            uint256 antiwhaleFee = getAntiwhaleFee(tAmount);
            appliedFees.liquidity = appliedFees.liquidity+antiwhaleFee;
        }

        }

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
                _tOwned[sender] = _tOwned[sender]-tAmount;
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
                _tOwned[sender] = _tOwned[sender]-tAmount;
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;

        if(takeFee)
        {
        _reflectRfi(s.rRfi, s.tRfi);
        address winner = _takeLottery(s.rLottery,s.tLottery);
        _takeMarketing(s.rMarketing,s.tMarketing);
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        _takeBurn(s.rBurn,s.tBurn);
        emit Transfer(sender, address(this), s.tMarketing+s.tLiquidity);
        if(winner==address(0))
        {
            emit Transfer(sender, address(0), s.tBurn+s.tLottery);
        }
        else
        {
            emit Transfer(sender, address(0), s.tBurn);
            emit Transfer(sender, winner , s.tLottery);
            emit LotteryWon(winner, s.tLottery); 

        }
        }
        emit Transfer(sender, recipient, s.tTransferAmount);
        if(!_isExcludedFromLottery[recipient])
        tokenHoldersEnumSet.add(recipient);

        if(balanceOf(sender)==0)
        tokenHoldersEnumSet.remove(sender);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        uint256 toSwap = contractTokenBalance/2;
        uint256 tokensToAddLiquidityWith = contractTokenBalance-toSwap;
        
        uint256 tokensBalance = balanceOf(address(this));
        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 bnbToAddLiquidityWith = address(this).balance-initialBalance;
        
        addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        uint256 tokensSwapped = tokensBalance - balanceOf(address(this));
        contractBalance.lp_balance-=tokensSwapped;
        
    }

    function swapAndSendToMarketing(uint256 tokenAmount) private lockTheSwap {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        if(allowance(address(this), address(PancakeSwapV2Router)) < tokenAmount) {
          _approve(address(this), address(PancakeSwapV2Router), ~uint256(0));
        }
        contractBalance.marketing_balance-=tokenAmount;
        PancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketingAddress,
            block.timestamp
        );


    }

    function swapTokensForBNB(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        if(allowance(address(this), address(PancakeSwapV2Router)) < tokenAmount) {
          _approve(address(this), address(PancakeSwapV2Router), ~uint256(0));
        }

        PancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {

        PancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, bnbAmount);
    }
    
    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

}