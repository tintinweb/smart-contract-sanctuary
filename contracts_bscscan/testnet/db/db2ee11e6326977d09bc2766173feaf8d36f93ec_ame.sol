/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed


abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);


    function allowance(address owner, address spender)
        external
        view
        returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }


    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() internal {
        address msgSender = _msgSender();
        _owner =msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IPancakeRouter01 {
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

// from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
interface IPancakeRouter02 is IPancakeRouter01 {
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

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
interface IPancakeFactory {
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

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
interface IPancakePair {
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

contract ame is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "ame";
    string private _symbol = "ame";
    uint8 private _decimals = 9;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _balanceLimit;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    mapping(address => uint256) public userLastBuy;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1_000_000_000_000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isTaxless;
    mapping(address=>bool) excludeFromMaxBuyLimit;
    mapping(address=>bool) excludeFromMaxSellLimit;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    
    uint256 public _feeDecimal = 2; // do not change this value...
    
    //BuyFee
    uint256 public _buyLiquidityFee=500;// meanse 5% liquidity
    uint256 public _buyBurnFee=500; // 1% burn fee
    
    //sell fee
    uint256 public _sellTaxFee=300; // 3% to all holders
    uint256 public _sellLiquidityFee=300;// meanse 5% liquidity
    uint256 public _marketingFee=100; //4% to marketing SwapAndLiquifyEnabledUpdated
    uint256 public _sellBurnFee=300; // 2% burn fee
    
    
    address donationAddress=0x7525970818c04fC1cf14F4c143bc09C9b67C8e93;
    address marketingAddress=0xdf0901E42Af739c7d3Af03B3AC64E653F4F2038D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    
    uint256 public _taxFeeTotal;
    uint256 public _burnFeeTotal;
    uint256 public _liquidityFeeTotal;

    bool public isFeeActive = true; // should be true
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public buyMaxTxAmount = 2_600_000e9; // 
    uint256 public sellMaxTxAmount = 300_000e9; // 
    
    uint256 public minTokensBeforeSwap = 100_000e9;
    uint256 public minTokenForLiquidity= 10_000_000e9;
  
    IPancakeRouter02 public  pancakeRouter;
    address public  pancakePair;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

      
       // isTaxless[owner()] = true;
        isTaxless[address(this)] = true;
        isTaxless[donationAddress] = true;
        isTaxless[marketingAddress] = true;
        
        // Exclude From Max Buy and sellMaxTxAmount
        
        excludeFromMaxBuyLimit[owner()] =true;
        excludeFromMaxSellLimit[owner()] =true;

        // exlcude pair address from tax rewards
        _isExcluded[address(pancakePair)] = true;
        _excluded.push(address(pancakePair));
        _isExcluded[DEAD]=true;
        _excluded.push(DEAD);

        _reflectionBalance[owner()] = _reflectionTotal;
        emit Transfer(address(0),owner(), _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        virtual
        returns (bool)
    {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"MOON: transfer amount exceeds allowance"));
        return true;
    }
    

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "MOON: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return
                tokenAmount.sub(tokenAmount.mul(_sellTaxFee).div(10** _feeDecimal + 2)).mul(
                    _getReflectionRate()
                );
        }
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(
            account != address(pancakePair),
            "MOON: We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "MOON: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "MOON: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "MOON: approve from the zero address");
        require(spender != address(0), "MOON: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "MOON: transfer from the zero address");
        require(recipient != address(0), "MOON: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        
        if(sender == pancakePair || recipient == pancakePair){
            
        uint256 donationBal=balanceOf(address(this));
        bool overMinTokenBalance = donationBal >= minTokensBeforeSwap;
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenLiquidityBalance = contractTokenBalance >= minTokenForLiquidity;
        
        if (!inSwapAndLiquify && overMinTokenLiquidityBalance && sender != pancakePair && swapAndLiquifyEnabled) {
            swapAndLiquify(contractTokenBalance);
        }
        
        if (!inSwapAndLiquify && overMinTokenBalance && sender != pancakePair && swapAndLiquifyEnabled) {
            
            _reflectionBalance[donationAddress] = _reflectionBalance[donationAddress].sub(donationBal.mul(rate));
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(donationBal.mul(rate));
            distributeTeam(donationBal);
        }
         
        }
    
        
        if(sender == pancakePair){
        require(amount <= buyMaxTxAmount || excludeFromMaxBuyLimit[recipient], "Buy Transfer Limit Exceeds");    
        if(!isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = collectBuyFee(sender,amount,rate);
        }
        
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
        
        return;
        }
        
        
        if(recipient == pancakePair) {
        require(amount <= sellMaxTxAmount || excludeFromMaxSellLimit[sender], "Transfer Limit Exceeds"); 
        if(!isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = collectSellFee(sender,amount,rate);
        }
        
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
        
        return;
        }
        
        
        if(!isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){
            transferAmount = collectSellFee(sender,amount,rate);
        }
        
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }
    
    function collectBuyFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        //@dev tax fee
        if(_buyLiquidityFee != 0){
            uint256 buyLiquidityFee = amount.mul(_buyLiquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(buyLiquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(buyLiquidityFee.mul(rate));
            if (_isExcluded[address(this)]) {
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(buyLiquidityFee);
            }
            emit Transfer(account,address(this),buyLiquidityFee);
        }
        
        if(_buyBurnFee != 0){
            uint256 burnFee = amount.mul(_buyBurnFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(burnFee);
            _tokenTotal = _tokenTotal.sub(burnFee);
            _reflectionBalance[DEAD] = _reflectionBalance[DEAD].add(burnFee.mul(rate));
            if (_isExcluded[DEAD]) {
                _tokenBalance[DEAD] = _tokenBalance[DEAD].add(burnFee);
            }
            _reflectionTotal = _reflectionTotal.sub(burnFee.mul(rate));
            _burnFeeTotal = _burnFeeTotal.add(burnFee);
            emit Transfer(account,DEAD,burnFee);
        }
        
        return transferAmount;
    }
    
    
    function collectSellFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        

        if(_sellLiquidityFee != 0){
            uint256 buyLiquidityFee = amount.mul(_sellLiquidityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(buyLiquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(buyLiquidityFee.mul(rate));
            if (_isExcluded[address(this)]) {
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(buyLiquidityFee);
            }
            emit Transfer(account,address(this),buyLiquidityFee);
        }
        
        if(_sellBurnFee != 0){
            uint256 burnFee = amount.mul(_sellBurnFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(burnFee);
            _tokenTotal = _tokenTotal.sub(burnFee);
            _reflectionBalance[DEAD] = _reflectionBalance[DEAD].add(burnFee.mul(rate));
            if (_isExcluded[DEAD]) {
                _tokenBalance[DEAD] = _tokenBalance[DEAD].add(burnFee);
            }
            _reflectionTotal = _reflectionTotal.sub(burnFee.mul(rate));
            _burnFeeTotal = _burnFeeTotal.add(burnFee);
            emit Transfer(account,DEAD,burnFee);
        }
        
        //@dev tax fee
        if(_sellTaxFee != 0){
            uint256 taxFee = amount.mul(_sellTaxFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
        }
        
          //Marketing tax fee
        if(_marketingFee != 0){
            uint256 marketingFee = amount.mul(_marketingFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(marketingFee);
            _reflectionBalance[marketingAddress] = _reflectionBalance[marketingAddress].add(marketingFee.mul(rate));
            if (_isExcluded[marketingAddress]) {
                _tokenBalance[marketingAddress] = _tokenBalance[marketingAddress].add(marketingFee);
            }
            emit Transfer(account,marketingAddress,marketingFee);
        }
        
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }
    
    
    function distributeTeam(uint256 amount) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(amount);
        uint256 amountToTranfer = address(this).balance.sub(initialBalance);
        
        payable(donationAddress).transfer(amountToTranfer);
    }
    
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);


        uint256 initialBalance = address(this).balance;


        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 newBalance = address(this).balance.sub(initialBalance);


        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function setPair(address pair) external onlyOwner {
        pancakePair = pair;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setFeeActive(bool value) external onlyOwner {
        isFeeActive = value;
    }
    
    //buytax
    
    function setBuyBurnFee(uint256 fee) external onlyOwner {
        _buyBurnFee=fee;
    }
    function setBuyLiqidityFee(uint256 fee) external onlyOwner {
        _buyLiquidityFee=fee;
    }
    
    // sell fee
    function setSellLiqidityFee(uint256 fee) external onlyOwner {
        _sellLiquidityFee=fee;
    }
    
    function setSellBurnFee(uint256 fee) external onlyOwner {
        _sellBurnFee=fee;
    }
    
    function setMarketingFee(uint256 fee) external onlyOwner {
        _marketingFee=fee;
    }
  
     function setSellTaxFee(uint256 fee) external onlyOwner {
        _sellTaxFee = fee;
    }
    
    function setMarketingAndDonationWalletAddress(address _marketingAddress,address _donationAddress) external onlyOwner {
        marketingAddress=_marketingAddress;
        donationAddress=_donationAddress;
    }
 
    function setBuyMaxTxAmount(uint256 amount) external onlyOwner {
        buyMaxTxAmount = amount;
    }
    
    function setExcludeFromMaxBuyLimit(address _address) external onlyOwner {
        excludeFromMaxBuyLimit[_address]=true;
    }
    
    function setExcludeFromMaxSellLimit(address _address) external onlyOwner {
        excludeFromMaxSellLimit[_address]=true;
    }
    
    function setSellMaxTxAmount(uint256 amount) external onlyOwner {
        sellMaxTxAmount = amount;
    }
    
    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }

    receive() external payable {}
}